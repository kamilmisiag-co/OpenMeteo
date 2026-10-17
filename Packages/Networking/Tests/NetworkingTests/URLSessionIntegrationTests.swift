//
//  URLSessionIntegrationTests.swift
//  NetworkingTests
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation
import Networking
import NetworkingMocks
import Synchronization
import Testing
import Utils

final class FixtureURLProtocol: URLProtocol {
    typealias Handler = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)

    static let handler = Mutex<Handler?>(nil)

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler.withLock({ $0 }) else {
            client?.urlProtocol(self, didFailWithError: URLError(.resourceUnavailable))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

@Suite("URL session integration", .serialized)
struct URLSessionIntegrationTests {
    init() {
        FixtureURLProtocol.handler.withLock { $0 = nil }
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FixtureURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    private func respond(_ handler: @escaping FixtureURLProtocol.Handler) {
        FixtureURLProtocol.handler.withLock { $0 = handler }
    }

    private static func response(to request: URLRequest, status: Int, headers: [String: String]) throws -> HTTPURLResponse {
        let url = try #require(request.url)
        return try #require(HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: headers))
    }

    @Test("A real URL session carries the built request and returns the decoded value")
    func roundTrip() async throws {
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        respond { request in
            guard request.url?.path() == "/base/v1/cities",
                  request.value(forHTTPHeaderField: "Accept") == "application/vnd.test+json",
                  request.value(forHTTPHeaderField: "X-Client") == "tests" else { throw URLError(.badURL) }
            return (try Self.response(to: request, status: 200, headers: ["Content-Type": "application/json"]), Fixtures.lisbonJSON)
        }
        let client = Fixtures.client(transport: URLSessionTransport(loader: session))
        #expect(try await client.send(CityEndpoint(name: "Lisbon")) == Fixtures.lisbon)
    }

    @Test("Server errors with Retry-After are retried through the real session")
    func retryAfterOverSession() async throws {
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        let attempts = Mutex(0)
        respond { request in
            let attempt = attempts.withLock { count in
                count += 1
                return count
            }
            if attempt == 1 {
                return (try Self.response(to: request, status: 503, headers: ["Retry-After": "2"]), Data())
            }
            return (try Self.response(to: request, status: 200, headers: [:]), Fixtures.lisbonJSON)
        }
        let sleeper = RecordingSleeper()
        let client = Fixtures.client(
            transport: URLSessionTransport(loader: session),
            retryPolicy: Fixtures.retryPolicy(maximumRetries: 2),
            sleeper: sleeper
        )
        #expect(try await client.send(CityEndpoint(name: "Lisbon")) == Fixtures.lisbon)
        #expect(attempts.withLock { $0 } == 2)
        #expect(await sleeper.durations == [.seconds(2)])
    }

    @Test("Losing the network surfaces as a connectivity error")
    func offline() async {
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        respond { _ in throw URLError(.notConnectedToInternet) }
        let client = Fixtures.client(transport: URLSessionTransport(loader: session))
        let error = await #expect(throws: NetworkError.self) {
            try await client.send(CityEndpoint(name: "Lisbon"))
        }
        #expect(error?.urlErrorCode == .notConnectedToInternet)
        #expect(error?.isConnectivity == true)
    }
}
