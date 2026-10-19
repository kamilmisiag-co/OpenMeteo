//
//  DataDecoding.swift
//  Utils
//
//  Created by Kamil Misiag on 19/10/2026.
//

import Foundation

public protocol DataDecoding: Sendable {
    func decode<Value: Decodable>(_ type: Value.Type, from data: Data) throws -> Value
}

extension JSONDecoder: DataDecoding {}
