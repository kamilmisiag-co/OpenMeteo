//
//  LoggerLaunchFailureReporter.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import OSLog

struct LoggerLaunchFailureReporter: LaunchFailureReporting {
    private let logger: Logger

    init(logger: Logger) {
        self.logger = logger
    }

    func report(_ error: any Error) {
        logger.error("Launch failed: \(String(describing: error), privacy: .public)")
    }
}
