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

    static func directory(named name: String, in root: URL) -> URL {
        root.appending(path: name, directoryHint: .isDirectory)
    }

    static func fileURL(named name: String, in directory: URL) -> URL {
        directory.appending(path: name, directoryHint: .notDirectory)
    }

    static func fileExists(_ url: URL) -> Bool {
        FileManager().fileExists(atPath: url.path(percentEncoded: false))
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
