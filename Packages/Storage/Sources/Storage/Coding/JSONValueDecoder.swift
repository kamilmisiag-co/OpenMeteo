//
//  JSONValueDecoder.swift
//  Storage
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation

public struct JSONValueDecoder: ValueDecoding {
    private let decoder: JSONDecoder

    public init(decoder: JSONDecoder) {
        self.decoder = decoder
    }

    public func decode<Value: Decodable>(_ type: Value.Type, from data: Data) throws -> Value {
        try decoder.decode(type, from: data)
    }
}
