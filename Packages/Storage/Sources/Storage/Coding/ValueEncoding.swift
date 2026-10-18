//
//  ValueEncoding.swift
//  Storage
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation

public protocol ValueEncoding: Sendable {
    func encode<Value: Encodable>(_ value: Value) throws -> Data
}
