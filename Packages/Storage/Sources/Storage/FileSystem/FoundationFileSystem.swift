//
//  FoundationFileSystem.swift
//  Storage
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation

public protocol FileSystemAccessing: Sendable {
    func contents(at url: URL) throws -> Data?
    func write(_ data: Data, to url: URL) throws
    func createDirectory(at url: URL) throws
}

public struct FoundationFileSystem: FileSystemAccessing {
    public init() {}

    public func contents(at url: URL) throws -> Data? {
        do {
            return try Data(contentsOf: url)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            return nil
        }
    }

    public func write(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: .atomic)
    }

    public func createDirectory(at url: URL) throws {
        try FileManager().createDirectory(at: url, withIntermediateDirectories: true)
    }
}
