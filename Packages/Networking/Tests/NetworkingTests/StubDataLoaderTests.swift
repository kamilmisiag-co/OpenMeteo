//
//  StubDataLoaderTests.swift
//  NetworkingTests
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation
import Networking
import NetworkingStubs
import Testing
import Utils
import UtilsMocks

@Suite("Stub data loader")
struct StubDataLoaderTests {
    private let citiesMatcher = StubRequestMatcher(method: .get, host: "api.example.test", path: "/base/v1/cities", queryItems: ["name": "Lisbon"])

    private func ok(_ body: Data, delay: Duration = .zero) -> StubResponse {
        StubResponse(outcome: .response(statusCode: 200, headers: ["ETag": "v1"], body: body), delay: delay)
    }

    private func status(_ code: Int) -> StubResponse {
        StubResponse(outcome: .response(statusCode: code, headers: [:], body: Data()), delay: .zero)
    }

    private func failure(_ code: URLError.Code) -> StubResponse {
        StubResponse(outcome: .failure(urlErrorCode: code.rawValue), delay: .zero)
    }

    private func request(_ query: String, method: HTTPMethod = .get) throws -> URLRequest {
        var request = URLRequest(url: try #require(URL(string: "https://api.example.test/base/v1/cities?\(query)")))
        request.httpMethod = method.rawValue
        return request
    }

    private func loader(_ stubs: [NetworkStub], unmatched: UnmatchedRequestPolicy = .fail(.notConnectedToInternet), sleeper: any Sleeping = RecordingSleeper()) -> StubDataLoader {
        StubDataLoader(stubs: stubs, unmatchedRequestPolicy: unmatched, sleeper: sleeper)
    }

    @Test("Matches on method, host, path and a subset of query items")
    func matching() async throws {
        let stub = loader([NetworkStub(matcher: citiesMatcher, responses: [ok(Fixtures.lisbonJSON)])])
        let transport = URLSessionTransport(loader: stub)

        let matched = try await transport.send(try request("name=Lisbon&count=10"))
        #expect(matched.statusCode == 200)
        #expect(matched.body == Fixtures.lisbonJSON)
        #expect(matched.value(forHeader: "etag") == "v1")

        for unmatched in [try request("name=Porto"), try request("name=Lisbon", method: .post)] {
            let error = await #expect(throws: NetworkError.self) { try await transport.send(unmatched) }
            #expect(error?.urlErrorCode == .notConnectedToInternet)
        }
        #expect(await stub.receivedRequests.count == 3)
    }

    @Test("The first matching stub wins and hosts match regardless of case")
    func firstMatchAndHostCase() async throws {
        let transport = URLSessionTransport(loader: loader([
            NetworkStub(matcher: citiesMatcher, responses: [status(503)]),
            NetworkStub(matcher: citiesMatcher, responses: [ok(Fixtures.lisbonJSON)]),
        ]))
        var upperCaseHost = try request("name=Lisbon")
        upperCaseHost.url = URL(string: "https://API.Example.Test/base/v1/cities?name=Lisbon")
        #expect(try await transport.send(upperCaseHost).statusCode == 503)
        #expect(try await transport.send(try request("name=Lisbon")).statusCode == 503)
    }

    @Test("Serves responses in order and repeats the last one")
    func sequence() async throws {
        let transport = URLSessionTransport(loader: loader([NetworkStub(matcher: citiesMatcher, responses: [status(503), ok(Fixtures.lisbonJSON)])]))
        var statuses: [Int] = []
        for _ in 0..<3 {
            statuses.append(try await transport.send(try request("name=Lisbon")).statusCode)
        }
        #expect(statuses == [503, 200, 200])
    }

    @Test("Waits for each response's delay through the injected sleeper")
    func delay() async throws {
        let sleeper = RecordingSleeper()
        let stub = loader([NetworkStub(matcher: citiesMatcher, responses: [ok(Fixtures.lisbonJSON, delay: .milliseconds(800))])], sleeper: sleeper)
        _ = try await URLSessionTransport(loader: stub).send(try request("name=Lisbon"))
        #expect(sleeper.durations == [.milliseconds(800)])
    }

    @Test("Failure outcomes go through the real transport's error mapping")
    func failures() async throws {
        let transport = URLSessionTransport(loader: loader([NetworkStub(matcher: citiesMatcher, responses: [failure(.timedOut), failure(.cancelled)])]))
        let timeout = await #expect(throws: NetworkError.self) { try await transport.send(try request("name=Lisbon")) }
        #expect(timeout?.urlErrorCode == .timedOut)
        let cancelled = await #expect(throws: NetworkError.self) { try await transport.send(try request("name=Lisbon")) }
        #expect(cancelled?.urlErrorCode == .cancelled)
    }

    @Test("Unmatched requests can get a fixed response instead of failing")
    func unmatchedResponse() async throws {
        let transport = URLSessionTransport(loader: loader([], unmatched: .respond(status(418))))
        #expect(try await transport.send(try request("name=Anywhere")).statusCode == 418)
    }

    @Test("Drives the real client end to end, including retries")
    func endToEnd() async throws {
        let sleeper = RecordingSleeper()
        let stub = loader([NetworkStub(matcher: citiesMatcher, responses: [status(503), ok(Fixtures.lisbonJSON)])])
        let client = Fixtures.client(
            transport: URLSessionTransport(loader: stub),
            retryPolicy: Fixtures.retryPolicy(maximumRetries: 1),
            sleeper: sleeper
        )
        #expect(try await client.send(CityEndpoint(name: "Lisbon")) == Fixtures.lisbon)
        #expect(sleeper.durations == [.seconds(1)])
        #expect(await stub.receivedRequests.count == 2)
    }
}
