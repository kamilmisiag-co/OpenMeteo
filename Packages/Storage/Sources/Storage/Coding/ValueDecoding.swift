//
//  ValueDecoding.swift
//  Storage
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation

public protocol ValueDecoding: Sendable {
    func decode<Value: Decodable>(_ type: Value.Type, from data: Data) throws -> Value
}
