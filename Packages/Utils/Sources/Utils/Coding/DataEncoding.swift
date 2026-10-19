//
//  DataEncoding.swift
//  Utils
//
//  Created by Kamil Misiag on 19/10/2026.
//

import Foundation

public protocol DataEncoding: Sendable {
    func encode<Value: Encodable>(_ value: Value) throws -> Data
}

extension JSONEncoder: DataEncoding {}
