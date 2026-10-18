//
//  StorageKeyEncoding.swift
//  Storage
//
//  Created by Kamil Misiag on 18/10/2026.
//

public protocol StorageKeyEncoding: Sendable {
    func fileName(forKey key: String) throws -> String
}
