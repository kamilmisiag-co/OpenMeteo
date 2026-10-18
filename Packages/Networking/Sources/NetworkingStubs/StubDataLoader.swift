//
//  StubDataLoader.swift
//  NetworkingStubs
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation
import Networking
import Utils

public actor StubDataLoader: URLSessionDataLoading {
    private let stubs: [NetworkStub]
    private let unmatchedRequestPolicy: UnmatchedRequestPolicy
    private let sleeper: any Sleeping
    private var servedCounts: [Int]
    public private(set) var receivedRequests: [URLRequest] = []

    public init(stubs: [NetworkStub], unmatchedRequestPolicy: UnmatchedRequestPolicy, sleeper: any Sleeping) {
        self.stubs = stubs
        self.unmatchedRequestPolicy = unmatchedRequestPolicy
        self.sleeper = sleeper
        servedCounts = Array(repeating: 0, count: stubs.count)
    }

    public func load(_ request: URLRequest) async throws -> (Data, URLResponse) {
        receivedRequests.append(request)
        let response = nextResponse(for: request)
        try await sleeper.sleep(for: response.delay)
        switch response.outcome {
        case .response(let statusCode, let headers, let body):
            guard let url = request.url,
                  let httpResponse = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: headers) else {
                throw URLError(.badURL)
            }
            return (body, httpResponse)
        case .failure(let rawCode):
            throw URLError(URLError.Code(rawValue: rawCode))
        }
    }

    private func nextResponse(for request: URLRequest) -> StubResponse {
        guard let index = stubs.firstIndex(where: { !$0.responses.isEmpty && $0.matcher.matches(request) }) else {
            return unmatchedResponse
        }
        let responses = stubs[index].responses
        let response = responses[min(servedCounts[index], responses.count - 1)]
        servedCounts[index] += 1
        return response
    }

    private var unmatchedResponse: StubResponse {
        switch unmatchedRequestPolicy {
        case .fail(let code): StubResponse(outcome: .failure(urlErrorCode: code.rawValue), delay: .zero)
        case .respond(let response): response
        }
    }
}
