//
//  MockHTTPClient.swift
//  NetworkingMocks
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Networking

public actor MockHTTPClient: HTTPClient {
    public typealias Handler = @Sendable (any Endpoint) async throws -> any Sendable

    private let handler: Handler
    public private(set) var endpoints: [any Endpoint] = []

    public init(handler: @escaping Handler) {
        self.handler = handler
    }

    public func send<E: Endpoint>(_ endpoint: E) async throws -> E.Response {
        endpoints.append(endpoint)
        let value = try await handler(endpoint)
        guard let response = value as? E.Response else {
            throw MockError.unexpectedResponseType(expected: String(describing: E.Response.self))
        }
        return response
    }
}
