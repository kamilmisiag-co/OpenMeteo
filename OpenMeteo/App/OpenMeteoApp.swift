//
//  OpenMeteoApp.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 15/10/2026.
//

import Foundation
import OSLog
import SwiftUI

@main
struct OpenMeteoApp: App {
    @State private var launch: AppLaunchState

    init() {
        let logSubsystem = Bundle.main.bundleIdentifier ?? AppStandard.fallbackLogSubsystem
        let launcher = AppLauncher(
            composer: Self.composer(logSubsystem: logSubsystem),
            failures: LoggerLaunchFailureReporter(logger: Logger(subsystem: logSubsystem, category: AppStandard.launchLogCategory))
        )
        _launch = State(initialValue: launcher.launch())
    }

    private static func composer(logSubsystem: String) -> any AppComposing {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains(AppStandard.sampleDataArgument) {
            return SampleAppComposer()
        }
        #endif
        return AppComposer(logSubsystem: logSubsystem)
    }

    var body: some Scene {
        WindowGroup {
            switch launch {
            case .ready(let session):
                RootView(session: session)
            case .failed:
                StartupFailureView()
            }
        }
    }
}
