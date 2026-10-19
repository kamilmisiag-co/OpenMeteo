//
//  FileDataStore.swift
//  Storage
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation

public protocol DataStoring: Sendable {
    func data(forKey key: String) throws -> Data?
    func write(_ data: Data, forKey key: String) throws
}

public struct FileDataStore: DataStoring {
    private let directory: URL
    private let fileSystem: any FileSystemAccessing
    private let fileNames: any StorageKeyEncoding

    public init(directory: URL, fileSystem: any FileSystemAccessing, fileNames: any StorageKeyEncoding) {
        self.directory = directory
        self.fileSystem = fileSystem
        self.fileNames = fileNames
    }

    public func data(forKey key: String) throws -> Data? {
        try fileSystem.contents(at: url(forKey: key))
    }

    public func write(_ data: Data, forKey key: String) throws {
        try fileSystem.createDirectory(at: directory)
        try fileSystem.write(data, to: url(forKey: key))
    }

    private func url(forKey key: String) -> URL {
        directory.appending(path: fileNames.fileName(forKey: key), directoryHint: .notDirectory)
    }
}
