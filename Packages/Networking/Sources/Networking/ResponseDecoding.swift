//
//  ResponseDecoding.swift
//  Networking
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation

public protocol ResponseDecoding: Sendable {
    func decode<Value: Decodable>(_ type: Value.Type, from data: Data) throws -> Value
}

public struct JSONResponseDecoder: ResponseDecoding {
    private let decoder: JSONDecoder

    public init(decoder: JSONDecoder) {
        self.decoder = decoder
    }

    public func decode<Value: Decodable>(_ type: Value.Type, from data: Data) throws -> Value {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw NetworkError.decoding(underlying: error)
        }
    }
}
