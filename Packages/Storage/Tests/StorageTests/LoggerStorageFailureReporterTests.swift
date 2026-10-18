//
//  LoggerStorageFailureReporterTests.swift
//  StorageTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import OSLog
import Storage
import Testing

@Suite("Logger storage failure reporter")
struct LoggerStorageFailureReporterTests {
    private enum ReportedError: Error {
        case corrupt
    }

    @Test("Every report is logged at error level with the operation kind, the key and the error")
    func logsReports() throws {
        let subsystem = "StorageTests.\(UUID().uuidString)"
        let reporter = LoggerStorageFailureReporter(logger: Logger(subsystem: subsystem, category: "storage"))
        let operations = StorageOperation.Kind.allCases.flatMap { kind in
            ["weather-2267057", "", "Kraków 🌧"].map { StorageOperation(kind: kind, key: $0) }
        }

        for operation in operations {
            reporter.report(ReportedError.corrupt, during: operation)
        }

        let store = try OSLogStore(scope: .currentProcessIdentifier)
        let entries = try store.getEntries(matching: NSPredicate(format: "subsystem == %@", subsystem))
            .compactMap { $0 as? OSLogEntryLog }
        #expect(entries.map(\.composedMessage) == operations.map { "Storage \($0.kind.rawValue) failed for \($0.key): corrupt" })
        #expect(entries.allSatisfy { $0.level == .error })
    }
}
