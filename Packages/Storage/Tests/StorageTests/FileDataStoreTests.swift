//
//  FileDataStoreTests.swift
//  StorageTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Storage
import Synchronization
import Testing

@Suite("File data store")
struct FileDataStoreTests {
    private enum FileSystemError: Error, Hashable {
        case unreadable
        case directoryUnavailable
        case unwritable
    }

    private final class RecordingFileSystem: FileSystemAccessing {
        enum Call: Hashable {
            case contents(URL)
            case createDirectory(URL)
            case write(Data, URL)
        }

        private let stored: Data?
        private let readError: FileSystemError?
        private let directoryError: FileSystemError?
        private let writeError: FileSystemError?
        private let recorded = Mutex<[Call]>([])

        init(
            stored: Data? = nil,
            readError: FileSystemError? = nil,
            directoryError: FileSystemError? = nil,
            writeError: FileSystemError? = nil
        ) {
            self.stored = stored
            self.readError = readError
            self.directoryError = directoryError
            self.writeError = writeError
        }

        var calls: [Call] {
            recorded.withLock { $0 }
        }

        func contents(at url: URL) throws -> Data? {
            recorded.withLock { $0.append(.contents(url)) }
            if let readError {
                throw readError
            }
            return stored
        }

        func write(_ data: Data, to url: URL) throws {
            recorded.withLock { $0.append(.write(data, url)) }
            if let writeError {
                throw writeError
            }
        }

        func createDirectory(at url: URL) throws {
            recorded.withLock { $0.append(.createDirectory(url)) }
            if let directoryError {
                throw directoryError
            }
        }
    }

    private struct PrefixingFileNames: StorageKeyEncoding {
        func fileName(forKey key: String) -> String {
            "stub-" + key + ".bin"
        }
    }

    private static let directory = URL(filePath: "/records/WeatherCache", directoryHint: .isDirectory)
    private static let payload = Data(#"{"id":2267057}"#.utf8)

    private static func expectedFile(_ name: String) -> URL {
        directory.appending(path: name, directoryHint: .notDirectory)
    }

    private static func store(on fileSystem: RecordingFileSystem) -> FileDataStore {
        FileDataStore(directory: directory, fileSystem: fileSystem, fileNames: PrefixingFileNames())
    }

    @Test("Reading asks the file system for the encoded file name inside the directory")
    func readsEncodedFile() throws {
        let fileSystem = RecordingFileSystem(stored: Self.payload)

        #expect(try Self.store(on: fileSystem).data(forKey: "weather-2267057") == Self.payload)

        let file = Self.expectedFile("stub-weather-2267057.bin")
        #expect(fileSystem.calls == [.contents(file)])
        #expect(file.path(percentEncoded: false) == "/records/WeatherCache/stub-weather-2267057.bin")
    }

    @Test("Writing creates the directory first and then writes the data to the encoded file")
    func writesAfterCreatingDirectory() throws {
        let fileSystem = RecordingFileSystem()

        try Self.store(on: fileSystem).write(Self.payload, forKey: "weather-2267057")

        let file = Self.expectedFile("stub-weather-2267057.bin")
        #expect(fileSystem.calls == [.createDirectory(Self.directory), .write(Self.payload, file)])
        #expect(file.path(percentEncoded: false) == "/records/WeatherCache/stub-weather-2267057.bin")
    }

    @Test("Read errors from the file system are thrown to the caller")
    func readErrorPropagates() {
        let fileSystem = RecordingFileSystem(stored: Self.payload, readError: .unreadable)

        #expect(throws: FileSystemError.unreadable) {
            try Self.store(on: fileSystem).data(forKey: "weather-1")
        }
        #expect(fileSystem.calls == [.contents(Self.expectedFile("stub-weather-1.bin"))])
    }

    @Test("A directory that can't be created is thrown and nothing is written")
    func directoryErrorPropagates() {
        let fileSystem = RecordingFileSystem(directoryError: .directoryUnavailable)

        #expect(throws: FileSystemError.directoryUnavailable) {
            try Self.store(on: fileSystem).write(Self.payload, forKey: "weather-1")
        }
        #expect(fileSystem.calls == [.createDirectory(Self.directory)])
    }

    @Test("Write errors from the file system are thrown to the caller")
    func writeErrorPropagates() {
        let fileSystem = RecordingFileSystem(writeError: .unwritable)

        #expect(throws: FileSystemError.unwritable) {
            try Self.store(on: fileSystem).write(Self.payload, forKey: "weather-1")
        }
        #expect(fileSystem.calls == [.createDirectory(Self.directory), .write(Self.payload, Self.expectedFile("stub-weather-1.bin"))])
    }

    @Test("Data written to disk reads back from a file named after the key in a directory created on demand")
    func diskRoundTrip() throws {
        let root = TestSupport.temporaryDirectory()
        defer { TestSupport.removeDirectory(root) }
        let directory = TestSupport.directory(named: StorageStandard.weatherCacheDirectoryName, in: root)
        let store = TestSupport.fileDataStore(in: directory)
        let lisbon = Data(#"{"name":"Lisbon"}"#.utf8)
        let bergen = Data(#"{"name":"Bergen"}"#.utf8)
        let replacement = Data("[]".utf8)

        #expect(try store.data(forKey: "weather-2267057") == nil)

        try store.write(lisbon, forKey: "weather-2267057")
        try store.write(bergen, forKey: "weather-3161732")

        #expect(try store.data(forKey: "weather-2267057") == lisbon)
        #expect(try store.data(forKey: "weather-3161732") == bergen)
        #expect(try Data(contentsOf: TestSupport.fileURL(named: "weather-2267057.json", in: directory)) == lisbon)
        #expect(try Set(FileManager().contentsOfDirectory(atPath: directory.path(percentEncoded: false))) == ["weather-2267057.json", "weather-3161732.json"])

        try store.write(replacement, forKey: "weather-2267057")

        #expect(try store.data(forKey: "weather-2267057") == replacement)
        #expect(try store.data(forKey: "weather-3161732") == bergen)
    }
}
