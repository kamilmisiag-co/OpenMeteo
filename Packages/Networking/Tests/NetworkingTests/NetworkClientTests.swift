//
//  NetworkClientTests.swift
//  NetworkingTests
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation
import Networking
import NetworkingMocks
import Testing
import Utils

@Suite("Network client")
struct NetworkClientTests {
    @Test("Builds the request, sends it and decodes the response")
    func success() async throws {
        let transport = MockHTTPTransport(whenExhausted: .fail, results: [.success(Fixtures.response(status: 200, body: Fixtures.lisbonJSON))])
        let city = try await Fixtures.client(transport: transport).send(CityEndpoint(name: "Lisbon"))
        #expect(city == Fixtures.lisbon)
        let request = try #require(await transport.requests.first)
        #expect(request.url?.path() == "/base/v1/cities")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/vnd.test+json")
    }

    @Test("Interceptors run in order on every attempt, starting from the built request")
    func interceptors() async throws {
        let transport = MockHTTPTransport(whenExhausted: .fail, results: [
            .success(Fixtures.response(status: 503)),
            .success(Fixtures.response(status: 200, body: Fixtures.lisbonJSON)),
        ])
        let calls = CallCounter()
        let client = Fixtures.client(
            transport: transport,
            retryPolicy: Fixtures.retryPolicy(maximumRetries: 1),
            interceptors: [
                ChainInterceptor(value: "a"),
                ChainInterceptor(value: "b"),
                HeaderInterceptor {
                    let attempt = await calls.increment()
                    return ["X-Attempt": "\(attempt)"]
                },
            ]
        )

        _ = try await client.send(CityEndpoint(name: "Lisbon"))

        let requests = await transport.requests
        #expect(requests.map { $0.value(forHTTPHeaderField: "X-Chain") } == ["ab", "ab"])
        #expect(requests.map { $0.value(forHTTPHeaderField: "X-Attempt") } == ["1", "2"])
    }

    @Test("An unacceptable status is thrown and reported to observers as one failure")
    func unacceptableStatus() async throws {
        let observer = RecordingNetworkObserver()
        let transport = MockHTTPTransport(whenExhausted: .fail, results: [.success(Fixtures.response(status: 404))])
        let client = Fixtures.client(transport: transport, observers: [observer])

        let error = await #expect(throws: NetworkError.self) {
            try await client.send(CityEndpoint(name: "Atlantis"))
        }

        #expect(error?.statusCode == 404)
        let request = try #require(await transport.requests.first)
        let events = observer.events
        #expect(events.count == 2)
        #expect(events.first == .willSend(request))
        if case .didFail(_, let failedRequest) = events.last {
            #expect(failedRequest == request)
        } else {
            Issue.record("Expected a failure event last, got \(String(describing: events.last))")
        }
    }

    @Test("Successful responses are reported once")
    func observerSuccess() async throws {
        let observer = RecordingNetworkObserver()
        let transport = MockHTTPTransport(whenExhausted: .fail, results: [.success(Fixtures.response(status: 200, body: Fixtures.lisbonJSON))])
        _ = try await Fixtures.client(transport: transport, observers: [observer]).send(CityEndpoint(name: "Lisbon"))
        let request = try #require(await transport.requests.first)
        #expect(observer.events == [.willSend(request), .didReceive(statusCode: 200, request)])
    }

    @Test("Retryable failures are retried after the policy's delay")
    func retriesThenSucceeds() async throws {
        let sleeper = RecordingSleeper()
        let transport = MockHTTPTransport(whenExhausted: .fail, results: [
            .success(Fixtures.response(status: 503, headers: ["Retry-After": "3"])),
            .success(Fixtures.response(status: 200, body: Fixtures.lisbonJSON)),
        ])
        let client = Fixtures.client(transport: transport, retryPolicy: Fixtures.retryPolicy(maximumRetries: 2), sleeper: sleeper)

        let city = try await client.send(CityEndpoint(name: "Lisbon"))

        #expect(city == Fixtures.lisbon)
        #expect(await transport.requests.count == 2)
        #expect(await sleeper.durations == [.seconds(3)])
    }

    @Test("Gives up with the last error once retries run out")
    func givesUp() async {
        let sleeper = RecordingSleeper()
        let transport = MockHTTPTransport(whenExhausted: .repeatLast, results: [.success(Fixtures.response(status: 503))])
        let client = Fixtures.client(transport: transport, retryPolicy: Fixtures.retryPolicy(maximumRetries: 2), sleeper: sleeper)

        let error = await #expect(throws: NetworkError.self) {
            try await client.send(CityEndpoint(name: "Lisbon"))
        }

        #expect(error?.statusCode == 503)
        #expect(await transport.requests.count == 3)
        #expect(await sleeper.durations == [.seconds(1), .seconds(2)])
    }

    @Test("Interceptor failures reach observers and follow the retry policy")
    func interceptorFailure() async throws {
        let observer = RecordingNetworkObserver()
        let calls = CallCounter()
        let transport = MockHTTPTransport(whenExhausted: .fail, results: [.success(Fixtures.response(status: 200, body: Fixtures.lisbonJSON))])
        let client = Fixtures.client(
            transport: transport,
            retryPolicy: Fixtures.retryPolicy(maximumRetries: 1),
            interceptors: [
                HeaderInterceptor {
                    if await calls.increment() == 1 { throw NetworkError.transport(URLError(.timedOut)) }
                    return ["Authorization": "token"]
                },
            ],
            observers: [observer]
        )

        #expect(try await client.send(CityEndpoint(name: "Lisbon")) == Fixtures.lisbon)

        #expect(await calls.count == 2)
        let sent = try #require(await transport.requests.first)
        #expect(sent.value(forHTTPHeaderField: "Authorization") == "token")
        let events = observer.events
        #expect(events.count == 4)
        guard events.count == 4, case .willSend(let failedRequest) = events[0] else {
            Issue.record("Unexpected events: \(events)")
            return
        }
        if case .didFail(_, let request) = events[1] {
            #expect(request == failedRequest)
        } else {
            Issue.record("Expected the interceptor failure second, got \(events[1])")
        }
        #expect(events[2] == .willSend(sent))
        #expect(events[3] == .didReceive(statusCode: 200, sent))
    }

    @Test("The retry policy judges the request that was actually sent")
    func policySeesInterceptedRequest() async {
        let transport = MockHTTPTransport(whenExhausted: .repeatLast, results: [.success(Fixtures.response(status: 503))])
        let client = Fixtures.client(
            transport: transport,
            retryPolicy: Fixtures.retryPolicy(maximumRetries: 3),
            interceptors: [MethodOverrideInterceptor(method: .post)]
        )
        await #expect(throws: NetworkError.self) {
            try await client.send(CityEndpoint(name: "Lisbon"))
        }
        #expect(await transport.requests.count == 1)
    }

    @Test("Cancellation is checked between attempts even when the sleeper doesn't throw")
    func cancellationBetweenAttempts() async {
        let transport = CancellingTransport(response: Fixtures.response(status: 503))
        let client = Fixtures.client(transport: transport, retryPolicy: Fixtures.retryPolicy(maximumRetries: 3), sleeper: SilentSleeper())
        let task = Task { try await client.send(CityEndpoint(name: "Lisbon")) }
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(await transport.requestCount == 1)
    }

    @Test("Failing mocks catch requests nobody expected")
    func exhaustedMock() async throws {
        let transport = MockHTTPTransport(whenExhausted: .fail, results: [.success(Fixtures.response(status: 200, body: Fixtures.lisbonJSON))])
        let client = Fixtures.client(transport: transport)
        _ = try await client.send(CityEndpoint(name: "Lisbon"))
        await #expect(throws: MockError.noResultQueued) {
            try await client.send(CityEndpoint(name: "Lisbon"))
        }
    }

    @Test("Methods outside the policy are sent once")
    func nonIdempotentNotRetried() async {
        let transport = MockHTTPTransport(whenExhausted: .fail, results: [.success(Fixtures.response(status: 503))])
        let client = Fixtures.client(transport: transport, retryPolicy: Fixtures.retryPolicy(maximumRetries: 3))
        await #expect(throws: NetworkError.self) {
            try await client.send(CreateCityEndpoint(city: Fixtures.lisbon))
        }
        #expect(await transport.requests.count == 1)
    }

    @Test("Cancellation passes straight through without retrying")
    func cancellation() async {
        let sleeper = RecordingSleeper()
        let transport = MockHTTPTransport(whenExhausted: .fail, results: [.failure(CancellationError())])
        let client = Fixtures.client(transport: transport, retryPolicy: Fixtures.retryPolicy(maximumRetries: 3), sleeper: sleeper)

        await #expect(throws: CancellationError.self) {
            try await client.send(CityEndpoint(name: "Lisbon"))
        }

        #expect(await transport.requests.count == 1)
        #expect(await sleeper.durations.isEmpty)
    }

    @Test("Decoding failures are not retried")
    func decodingFailure() async {
        let transport = MockHTTPTransport(whenExhausted: .fail, results: [.success(Fixtures.response(status: 200, body: Data("{}".utf8)))])
        let client = Fixtures.client(transport: transport, retryPolicy: Fixtures.retryPolicy(maximumRetries: 3))
        let error = await #expect(throws: NetworkError.self) {
            try await client.send(CityEndpoint(name: "Lisbon"))
        }
        #expect(error?.caseName == "decoding")
        #expect(await transport.requests.count == 1)
    }

    @Test("Empty responses skip decoding")
    func emptyResponse() async throws {
        let transport = MockHTTPTransport(whenExhausted: .fail, results: [.success(Fixtures.response(status: 204))])
        let result = try await Fixtures.client(transport: transport).send(UploadEndpoint(payload: Data([1]), contentTypeOverride: nil))
        #expect(result == EmptyResponse())
    }

    @Test("Offline transport errors stay recognisable as connectivity errors")
    func connectivityClassification() async {
        let transport = MockHTTPTransport(whenExhausted: .fail, results: [.failure(NetworkError.transport(URLError(.notConnectedToInternet)))])
        let error = await #expect(throws: NetworkError.self) {
            try await Fixtures.client(transport: transport).send(CityEndpoint(name: "Lisbon"))
        }
        #expect(error?.isConnectivity == true)
        #expect(error?.isCancellation == false)
    }

    @Test("The mock client hands back typed responses and records endpoints")
    func mockClient() async throws {
        let client = MockHTTPClient { endpoint in
            if (endpoint as? CityEndpoint)?.name == "Lisbon" {
                return Fixtures.lisbon
            }
            return EmptyResponse()
        }
        #expect(try await client.send(CityEndpoint(name: "Lisbon")) == Fixtures.lisbon)
        let error = await #expect(throws: MockError.self) {
            try await client.send(CityEndpoint(name: "Elsewhere"))
        }
        #expect(error == .unexpectedResponseType(expected: "TestCity"))
        #expect(await client.endpoints.count == 2)
    }
}
