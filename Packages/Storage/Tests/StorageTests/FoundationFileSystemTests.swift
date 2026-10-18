//
//  FoundationFileSystemTests.swift
//  StorageTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Storage
import Testing

@Suite("Foundation file system")
struct FoundationFileSystemTests {
    private static func isDirectory(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager().fileExists(atPath: url.path(percentEncoded: false), isDirectory: &isDirectory) && isDirectory.boolValue
    }

    private static func fileNumber(of url: URL) throws -> UInt64 {
        let attributes = try FileManager().attributesOfItem(atPath: url.path(percentEncoded: false))
        let number = try #require(attributes[.systemFileNumber] as? NSNumber)
        return number.uint64Value
    }

    @Test("Written data reads back unchanged")
    func roundTrip() throws {
        let directory = TestSupport.temporaryDirectory()
        defer { TestSupport.removeDirectory(directory) }
        let fileSystem = FoundationFileSystem()
        let file = TestSupport.fileURL(named: "record.json", in: directory)
        let data = Data(#"{"name":"Lisbon","id":2267057}"#.utf8)

        try fileSystem.createDirectory(at: directory)
        try fileSystem.write(data, to: file)

        #expect(try fileSystem.contents(at: file) == data)
    }

    @Test("Reading a file that doesn't exist gives nil")
    func missingFile() throws {
        let directory = TestSupport.temporaryDirectory()
        defer { TestSupport.removeDirectory(directory) }
        let fileSystem = FoundationFileSystem()
        try fileSystem.createDirectory(at: directory)

        #expect(try fileSystem.contents(at: TestSupport.fileURL(named: "missing.json", in: directory)) == nil)
    }

    @Test("Reading from a directory that doesn't exist gives nil")
    func missingDirectory() throws {
        let directory = TestSupport.temporaryDirectory()
        defer { TestSupport.removeDirectory(directory) }

        #expect(try FoundationFileSystem().contents(at: TestSupport.fileURL(named: "missing.json", in: directory)) == nil)
        #expect(!TestSupport.fileExists(directory))
    }

    @Test("Reading something that isn't a readable file throws instead of giving nil")
    func unreadableFile() throws {
        let directory = TestSupport.temporaryDirectory()
        defer { TestSupport.removeDirectory(directory) }
        let fileSystem = FoundationFileSystem()
        try fileSystem.createDirectory(at: directory)

        #expect(throws: (any Error).self) {
            try fileSystem.contents(at: directory)
        }
    }

    @Test(
        "Reading a file without read permission throws the permission error instead of giving nil",
        .enabled(if: geteuid() != 0, "Root reads files regardless of their permissions")
    )
    func fileWithoutReadPermission() throws {
        let directory = TestSupport.temporaryDirectory()
        defer { TestSupport.removeDirectory(directory) }
        let fileSystem = FoundationFileSystem()
        let file = TestSupport.fileURL(named: "record.json", in: directory)
        let path = file.path(percentEncoded: false)
        try fileSystem.createDirectory(at: directory)
        try fileSystem.write(Data("private".utf8), to: file)
        try FileManager().setAttributes([.posixPermissions: 0o000], ofItemAtPath: path)
        defer { try? FileManager().setAttributes([.posixPermissions: 0o600], ofItemAtPath: path) }
        try #require(!FileManager().isReadableFile(atPath: path))

        let error = try #require(throws: CocoaError.self) {
            try fileSystem.contents(at: file)
        }
        #expect(error.code == .fileReadNoPermission)
    }

    @Test("Overwriting a file replaces its whole content")
    func overwrite() throws {
        let directory = TestSupport.temporaryDirectory()
        defer { TestSupport.removeDirectory(directory) }
        let fileSystem = FoundationFileSystem()
        let file = TestSupport.fileURL(named: "record.json", in: directory)
        let replacement = Data("short".utf8)
        try fileSystem.createDirectory(at: directory)

        try fileSystem.write(Data("a much longer first payload that must not leak into the second".utf8), to: file)
        try fileSystem.write(replacement, to: file)

        #expect(try fileSystem.contents(at: file) == replacement)
    }

    @Test("Overwriting an existing file puts a new file in its place instead of writing into the old one")
    func overwriteReplacesFile() throws {
        let directory = TestSupport.temporaryDirectory()
        defer { TestSupport.removeDirectory(directory) }
        let fileSystem = FoundationFileSystem()
        let file = TestSupport.fileURL(named: "record.json", in: directory)
        try fileSystem.createDirectory(at: directory)
        try fileSystem.write(Data("first".utf8), to: file)
        let original = try Self.fileNumber(of: file)

        try fileSystem.write(Data("second".utf8), to: file)

        #expect(try Self.fileNumber(of: file) != original)
    }

    @Test("Writing leaves only the destination file behind")
    func noLeftovers() throws {
        let directory = TestSupport.temporaryDirectory()
        defer { TestSupport.removeDirectory(directory) }
        let fileSystem = FoundationFileSystem()
        let file = TestSupport.fileURL(named: "record.json", in: directory)
        try fileSystem.createDirectory(at: directory)

        try fileSystem.write(Data("first".utf8), to: file)
        try fileSystem.write(Data("second".utf8), to: file)

        #expect(try FileManager().contentsOfDirectory(atPath: directory.path(percentEncoded: false)) == ["record.json"])
    }

    @Test("Creating a directory also creates its missing parents")
    func createsIntermediates() throws {
        let root = TestSupport.temporaryDirectory()
        defer { TestSupport.removeDirectory(root) }
        let fileSystem = FoundationFileSystem()
        let nested = root
            .appending(path: "Caches", directoryHint: .isDirectory)
            .appending(path: "Storage", directoryHint: .isDirectory)
            .appending(path: "WeatherCache", directoryHint: .isDirectory)
        let file = TestSupport.fileURL(named: "record.json", in: nested)
        let data = Data("nested".utf8)

        try fileSystem.createDirectory(at: nested)

        #expect(Self.isDirectory(nested))
        try fileSystem.write(data, to: file)
        #expect(try fileSystem.contents(at: file) == data)
    }

    @Test("Creating a directory that already exists succeeds and keeps its files")
    func createDirectoryIsIdempotent() throws {
        let directory = TestSupport.temporaryDirectory()
        defer { TestSupport.removeDirectory(directory) }
        let fileSystem = FoundationFileSystem()
        let file = TestSupport.fileURL(named: "record.json", in: directory)
        let data = Data("kept".utf8)

        try fileSystem.createDirectory(at: directory)
        try fileSystem.write(data, to: file)
        try fileSystem.createDirectory(at: directory)
        try fileSystem.createDirectory(at: directory)

        #expect(Self.isDirectory(directory))
        #expect(try fileSystem.contents(at: file) == data)
    }

    @Test("Writing into a directory that doesn't exist throws and creates nothing")
    func writeWithoutDirectory() throws {
        let directory = TestSupport.temporaryDirectory()
        defer { TestSupport.removeDirectory(directory) }
        let fileSystem = FoundationFileSystem()
        let file = TestSupport.fileURL(named: "record.json", in: directory)

        #expect(throws: (any Error).self) {
            try fileSystem.write(Data("orphan".utf8), to: file)
        }
        #expect(!TestSupport.fileExists(file))
        #expect(!TestSupport.fileExists(directory))
    }
}
