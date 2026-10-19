//
//  AppLauncher.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

struct AppLauncher {
    private let composer: any AppComposing
    private let failureReporter: any LaunchFailureReporting

    init(composer: any AppComposing, failures: any LaunchFailureReporting) {
        self.composer = composer
        failureReporter = failures
    }

    func launch() -> AppLaunchState {
        do {
            return .ready(try composer.makeSession())
        } catch {
            failureReporter.report(error)
            return .failed
        }
    }
}
