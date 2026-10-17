//
//  BodyEncoding.swift
//  Networking
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation

public protocol BodyEncoding: Sendable {
    var contentType: String { get }

    func encode(_ value: any Encodable & Sendable) throws -> Data
}

public struct JSONBodyEncoder: BodyEncoding {
    public let contentType: String
    private let encoder: JSONEncoder

    public init(encoder: JSONEncoder, contentType: String) {
        self.encoder = encoder
        self.contentType = contentType
    }

    public func encode(_ value: any Encodable & Sendable) throws -> Data {
        do {
            return try encoder.encode(value)
        } catch {
            throw NetworkError.encoding(underlying: error)
        }
    }
}
