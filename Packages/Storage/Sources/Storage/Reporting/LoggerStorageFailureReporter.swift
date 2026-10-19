//
//  LoggerStorageFailureReporter.swift
//  Storage
//
//  Created by Kamil Misiag on 18/10/2026.
//

import OSLog

public protocol StorageFailureReporting: Sendable {
    func report(_ error: any Error, during operation: StorageOperation)
}

public struct LoggerStorageFailureReporter: StorageFailureReporting {
    private let logger: Logger

    public init(logger: Logger) {
        self.logger = logger
    }

    public func report(_ error: any Error, during operation: StorageOperation) {
        logger.error("Storage \(operation.kind.rawValue, privacy: .public) failed for \(operation.key, privacy: .public): \(String(describing: error), privacy: .private)")
    }
}
