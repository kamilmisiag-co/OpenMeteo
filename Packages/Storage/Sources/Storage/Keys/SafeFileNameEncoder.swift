//
//  SafeFileNameEncoder.swift
//  Storage
//
//  Created by Kamil Misiag on 18/10/2026.
//

public protocol StorageKeyEncoding: Sendable {
    func fileName(forKey key: String) -> String
}

public struct SafeFileNameEncoder: StorageKeyEncoding {
    private let fileExtension: String

    public init(fileExtension: String) {
        self.fileExtension = fileExtension
    }

    public func fileName(forKey key: String) -> String {
        fileExtension.isEmpty ? key : key + "." + fileExtension
    }
}
