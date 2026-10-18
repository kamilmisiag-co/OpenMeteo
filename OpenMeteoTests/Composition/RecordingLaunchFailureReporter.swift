//
//  RecordingLaunchFailureReporter.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

@testable import OpenMeteo

@MainActor
final class RecordingLaunchFailureReporter: LaunchFailureReporting {
    private(set) var errors: [AppCompositionError] = []
    private(set) var otherErrorCount = 0

    func report(_ error: any Error) {
        guard let error = error as? AppCompositionError else {
            otherErrorCount += 1
            return
        }
        errors.append(error)
    }
}
