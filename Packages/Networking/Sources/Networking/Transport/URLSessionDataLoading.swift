//
//  URLSessionDataLoading.swift
//  Networking
//
//  Created by Kamil Misiag on 19/10/2026.
//

import Foundation

public protocol URLSessionDataLoading: Sendable {
    func load(_ request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionDataLoading {
    public func load(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: request)
    }
}
