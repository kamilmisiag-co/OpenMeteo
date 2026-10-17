//
//  HTTPClient.swift
//  Networking
//
//  Created by Kamil Misiag on 16/10/2026.
//

public protocol HTTPClient: Sendable {
    func send<E: Endpoint>(_ endpoint: E) async throws -> E.Response
}
