//
//  SafeFileNameEncoder.swift
//  Storage
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation

public struct SafeFileNameEncoder: StorageKeyEncoding {
    private let allowedCharacters: CharacterSet
    private let fileExtension: String

    public init(allowedCharacters: CharacterSet, fileExtension: String) {
        self.allowedCharacters = allowedCharacters
        self.fileExtension = fileExtension
    }

    public func fileName(forKey key: String) throws -> String {
        guard !key.isEmpty, key.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else {
            throw StorageError.invalidKey(key)
        }
        return fileExtension.isEmpty ? key : key + "." + fileExtension
    }
}
