//
//  TestSupport.swift
//  StorageTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Storage
import Synchronization

enum TestSupport {
    static func temporaryDirectory() -> URL {
        URL(filePath: NSTemporaryDirectory(), directoryHint: .isDirectory)
            .appending(path: "StorageTests-\(UUID().uuidString)", directoryHint: .isDirectory)
    }

    static func removeDirectory(_ url: URL) {
        try? FileManager().removeItem(at: url)
    }

    static func fileDataStore(in directory: URL) -> FileDataStore {
        FileDataStore(directory: directory, fileSystem: FoundationFileSystem(), fileNames: Fixtures.standardFileNames)
    }

    static func recordStore(in directory: URL, reporter: any StorageFailureReporting) -> ReportingRecordStore {
        ReportingRecordStore(
            store: fileDataStore(in: directory),
            encoder: JSONValueEncoder(encoder: JSONEncoder()),
            decoder: JSONValueDecoder(decoder: JSONDecoder()),
            reporter: reporter
        )
    }

    static func directory(named name: String, in root: URL) -> URL {
        root.appending(path: name, directoryHint: .isDirectory)
    }

    static func fileURL(named name: String, in directory: URL) -> URL {
        directory.appending(path: name, directoryHint: .notDirectory)
    }

    static func fileExists(_ url: URL) -> Bool {
        FileManager().fileExists(atPath: url.path(percentEncoded: false))
    }

    static func write(_ payload: String, to file: URL) throws {
        try FileManager().createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(payload.utf8).write(to: file)
    }
}

final class RecordingReporter: StorageFailureReporting {
    struct Report {
        let error: any Error
        let operation: StorageOperation
    }

    private let recorded = Mutex<[Report]>([])

    var reports: [Report] {
        recorded.withLock { $0 }
    }

    var operations: [StorageOperation] {
        reports.map(\.operation)
    }

    func report(_ error: any Error, during operation: StorageOperation) {
        recorded.withLock { $0.append(Report(error: error, operation: operation)) }
    }
}

struct RecordRead: Equatable {
    let type: ObjectIdentifier
    let key: String

    init(_ type: Any.Type, key: String) {
        self.type = ObjectIdentifier(type)
        self.key = key
    }
}

final class RecordingRecordStore<Stored: Equatable & Sendable>: RecordStoring {
    struct Save: Equatable {
        let type: ObjectIdentifier
        let key: String
        let record: Stored?

        init(_ type: Any.Type, key: String, record: Stored?) {
            self.type = ObjectIdentifier(type)
            self.key = key
            self.record = record
        }
    }

    private struct State {
        let stored: Stored?
        var reads: [RecordRead] = []
        var saves: [Save] = []
    }

    private let state: Mutex<State>

    init(stored: Stored?) {
        state = Mutex(State(stored: stored))
    }

    var reads: [RecordRead] {
        state.withLock { $0.reads }
    }

    var saves: [Save] {
        state.withLock { $0.saves }
    }

    func record<Record: Decodable>(_ type: Record.Type, forKey key: String) -> Record? {
        let stored = state.withLock { state in
            state.reads.append(RecordRead(type, key: key))
            return state.stored
        }
        return stored.flatMap { $0 as? Record }
    }

    func save<Record: Encodable>(_ record: Record, forKey key: String) {
        let save = Save(Record.self, key: key, record: record as? Stored)
        state.withLock { $0.saves.append(save) }
    }
}
