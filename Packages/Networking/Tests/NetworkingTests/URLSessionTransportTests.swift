//
//  URLSessionTransportTests.swift
//  NetworkingTests
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation
import Networking
import NetworkingMocks
import Testing

struct CancellingLoader: URLSessionDataLoading {
    func load(_ request: URLRequest) async throws -> (Data, URLResponse) {
        withUnsafeCurrentTask { $0?.cancel() }
        throw URLError(.cancelled)
    }
}

@Suite("URL session transport")
struct URLSessionTransportTests {
    private let url = URL(string: "https://api.example.test/base/v1/cities")!

    @Test("Maps an HTTP URL response to an HTTPResponse and forwards the request unchanged")
    func mapsResponse() async throws {
        let http = try #require(HTTPURLResponse(url: url, statusCode: 201, httpVersion: "HTTP/1.1", headerFields: ["ETag": "abc"]))
        let loader = MockDataLoader(whenExhausted: .fail, results: [.success((Fixtures.lisbonJSON, http))])
        let request = URLRequest(url: url)

        let response = try await URLSessionTransport(loader: loader).send(request)

        #expect(response.statusCode == 201)
        #expect(response.value(forHeader: "etag") == "abc")
        #expect(response.body == Fixtures.lisbonJSON)
        #expect(response.url == url)
        #expect(await loader.requests == [request])
    }

    @Test("A response that isn't HTTP is rejected")
    func nonHTTPResponse() async {
        let plain = URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        let transport = URLSessionTransport(loader: MockDataLoader(whenExhausted: .fail, results: [.success((Data(), plain))]))
        let error = await #expect(throws: NetworkError.self) {
            try await transport.send(URLRequest(url: url))
        }
        #expect(error?.caseName == "nonHTTPResponse")
    }

    @Test("URL errors become transport errors with the same code")
    func transportError() async {
        let transport = URLSessionTransport(loader: MockDataLoader(whenExhausted: .fail, results: [.failure(URLError(.timedOut))]))
        let error = await #expect(throws: NetworkError.self) {
            try await transport.send(URLRequest(url: url))
        }
        #expect(error?.urlErrorCode == .timedOut)
    }

    @Test("A cancelled load in a cancelled task surfaces as task cancellation")
    func taskCancellation() async {
        let transport = URLSessionTransport(loader: CancellingLoader())
        let request = URLRequest(url: url)
        let task = Task { try await transport.send(request) }
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    @Test("A cancelled load without task cancellation stays a transport error")
    func cancelledWithoutTaskCancellation() async {
        let transport = URLSessionTransport(loader: MockDataLoader(whenExhausted: .fail, results: [.failure(URLError(.cancelled))]))
        let error = await #expect(throws: NetworkError.self) {
            try await transport.send(URLRequest(url: url))
        }
        #expect(error?.urlErrorCode == .cancelled)
    }
}
