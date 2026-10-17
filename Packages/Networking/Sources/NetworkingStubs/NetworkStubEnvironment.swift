//
//  NetworkStubEnvironment.swift
//  NetworkingStubs
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation

public struct NetworkStubEnvironment: Sendable {
    private let key: String
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(key: String, encoder: JSONEncoder, decoder: JSONDecoder) {
        self.key = key
        self.encoder = encoder
        self.decoder = decoder
    }

    public func environment(for stubs: [NetworkStub]) throws -> [String: String] {
        [key: String(decoding: try encoder.encode(stubs), as: UTF8.self)]
    }

    public func stubs(from environment: [String: String]) throws -> [NetworkStub]? {
        guard let value = environment[key] else { return nil }
        return try decoder.decode([NetworkStub].self, from: Data(value.utf8))
    }
}
