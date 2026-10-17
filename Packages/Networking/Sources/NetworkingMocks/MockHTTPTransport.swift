//
//  MockHTTPTransport.swift
//  NetworkingMocks
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation
import Networking

public actor MockHTTPTransport: HTTPTransport {
    private var queue: ResultQueue<HTTPResponse>
    public private(set) var requests: [URLRequest] = []

    public init(whenExhausted exhaustion: ExhaustionBehavior, results: [Result<HTTPResponse, any Error>]) {
        queue = ResultQueue(results, repeatsLast: exhaustion == .repeatLast)
    }

    public func send(_ request: URLRequest) async throws -> HTTPResponse {
        requests.append(request)
        guard let result = queue.next() else { throw MockError.noResultQueued }
        return try result.get()
    }
}
