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
import UtilsMocks

@Suite("Network client")
struct NetworkClientTests {
    @Test("Builds the request, sends it and decodes the response")
    func success() async throws {
        let transport = MockHTTPTransport(whenExhausted: .fail, results: [.success(NetworkFixtures.response(status: 200, body: Fixtures.lisbonJSON))])
        let city = try await Fixtures.client(transport: transport).send(CityEndpoint(name: "Lisbon"))
        #expect(city == Fixtures.lisbon)
        let request = try #require(await transport.requests.first)
        #expect(request.url?.path() == "/base/v1/cities")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/vnd.test+json")
    }

    @Test("An unacceptable status is thrown and reported to observers as one failure")
    func unacceptableStatus() async throws {
        let observer = RecordingNetworkObserver()
        let transport = MockHTTPTransport(whenExhausted: .fail, results: [.success(NetworkFixtures.response(status: 404))])
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
        let transport = MockHTTPTransport(whenExhausted: .fail, results: [.success(NetworkFixtures.response(status: 200, body: Fixtures.lisbonJSON))])
        _ = try await Fixtures.client(transport: transport, observers: [observer]).send(CityEndpoint(name: "Lisbon"))
        let request = try #require(await transport.requests.first)
        #expect(observer.events == [.willSend(request), .didReceive(statusCode: 200, request)])
    }

    @Test("Retryable failures are retried after the policy's delay")
    func retriesThenSucceeds() async throws {
        let sleeper = RecordingSleeper()
        let transport = MockHTTPTransport(whenExhausted: .fail, results: [
            .success(NetworkFixtures.response(status: 503, retryAfter: "3")),
            .success(NetworkFixtures.response(status: 200, body: Fixtures.lisbonJSON)),
        ])
        let client = Fixtures.client(transport: transport, retryPolicy: Fixtures.retryPolicy(maximumRetries: 2), sleeper: sleeper)

        let city = try await client.send(CityEndpoint(name: "Lisbon"))

        #expect(city == Fixtures.lisbon)
        #expect(await transport.requests.count == 2)
        #expect(sleeper.durations == [.seconds(3)])
    }

    @Test("Gives up with the last error once retries run out")
    func givesUp() async {
        let sleeper = RecordingSleeper()
        let transport = MockHTTPTransport(whenExhausted: .repeatLast, results: [.success(NetworkFixtures.response(status: 503))])
        let client = Fixtures.client(transport: transport, retryPolicy: Fixtures.retryPolicy(maximumRetries: 2), sleeper: sleeper)

        let error = await #expect(throws: NetworkError.self) {
            try await client.send(CityEndpoint(name: "Lisbon"))
        }

        #expect(error?.statusCode == 503)
        #expect(await transport.requests.count == 3)
        #expect(sleeper.durations == [.seconds(1), .seconds(2)])
    }

    @Test("The retry policy judges the request that was actually sent")
    func policySeesInterceptedRequest() async {
        let transport = MockHTTPTransport(whenExhausted: .repeatLast, results: [.success(NetworkFixtures.response(status: 503))])
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
        let transport = CancellingTransport(response: NetworkFixtures.response(status: 503))
        let client = Fixtures.client(transport: transport, retryPolicy: Fixtures.retryPolicy(maximumRetries: 3), sleeper: RecordingSleeper(checksCancellation: false))
        let task = Task { try await client.send(CityEndpoint(name: "Lisbon")) }
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(await transport.requestCount == 1)
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
        #expect(sleeper.durations.isEmpty)
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
}
