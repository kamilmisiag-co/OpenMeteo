//
//  StorageError.swift
//  Storage
//
//  Created by Kamil Misiag on 18/10/2026.
//

public enum StorageError: Error, Hashable, Sendable {
    case invalidKey(String)
}
