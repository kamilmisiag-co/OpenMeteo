//
//  JSONValueEncoder.swift
//  Storage
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation

public struct JSONValueEncoder: ValueEncoding {
    private let encoder: JSONEncoder

    public init(encoder: JSONEncoder) {
        self.encoder = encoder
    }

    public func encode<Value: Encodable>(_ value: Value) throws -> Data {
        try encoder.encode(value)
    }
}
