//
//  StorageOperation.swift
//  Storage
//
//  Created by Kamil Misiag on 18/10/2026.
//

public struct StorageOperation: Hashable, Sendable {
    public enum Kind: String, CaseIterable, Hashable, Sendable {
        case read
        case write
        case encode
        case decode
    }

    public let kind: Kind
    public let key: String

    public init(kind: Kind, key: String) {
        self.kind = kind
        self.key = key
    }
}
