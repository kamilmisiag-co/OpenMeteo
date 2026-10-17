//
//  MockDataLoader.swift
//  NetworkingMocks
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation
import Networking

public actor MockDataLoader: URLSessionDataLoading {
    private var queue: ResultQueue<(Data, URLResponse)>
    public private(set) var requests: [URLRequest] = []

    public init(whenExhausted exhaustion: ExhaustionBehavior, results: [Result<(Data, URLResponse), any Error>]) {
        queue = ResultQueue(results, repeatsLast: exhaustion == .repeatLast)
    }

    public func load(_ request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        guard let result = queue.next() else { throw MockError.noResultQueued }
        return try result.get()
    }
}
