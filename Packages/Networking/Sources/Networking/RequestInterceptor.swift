//
//  RequestInterceptor.swift
//  Networking
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation

public protocol RequestInterceptor: Sendable {
    func intercept(_ request: URLRequest) async throws -> URLRequest
}

public struct HeaderInterceptor: RequestInterceptor {
    public typealias HeaderProvider = @Sendable () async throws -> [String: String]

    private let provider: HeaderProvider

    public init(provider: @escaping HeaderProvider) {
        self.provider = provider
    }

    public func intercept(_ request: URLRequest) async throws -> URLRequest {
        var request = request
        for (field, value) in try await provider() {
            request.setValue(value, forHTTPHeaderField: field)
        }
        return request
    }
}
