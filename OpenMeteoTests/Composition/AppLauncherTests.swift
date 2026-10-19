//
//  AppLauncherTests.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
@testable import OpenMeteo
import Testing

@MainActor
@Suite("App launch")
struct AppLauncherTests {
    private func makeSession() -> AppSession {
        AppSession(
            search: SearchViewModel(dependencies: ViewModelFixtures.searchDependencies()),
            links: AttributionLinks(openMeteo: nil, licence: nil, geoNames: nil),
            dayCount: 7
        )
    }

    @Test("Launch is ready with the session the composer made and reports nothing")
    func ready() {
        let session = makeSession()
        let composer = StubAppComposer(result: .success(session))
        let failures = RecordingLaunchFailureReporter()

        let state = AppLauncher(composer: composer, failures: failures).launch()

        guard case .ready(let launched) = state else {
            Issue.record("Expected a ready launch state")
            return
        }
        #expect(launched === session)
        #expect(composer.callCount == 1)
        #expect(failures.errors.isEmpty)
        #expect(failures.otherErrorCount == 0)
    }

    @Test("Launch fails and reports the error when composition throws")
    func failed() {
        let error = AppCompositionError.invalidBaseURL(host: "bad host")
        let composer = StubAppComposer(result: .failure(error))
        let failures = RecordingLaunchFailureReporter()

        let state = AppLauncher(composer: composer, failures: failures).launch()

        guard case .failed = state else {
            Issue.record("Expected a failed launch state")
            return
        }
        #expect(composer.callCount == 1)
        #expect(failures.errors == [error])
        #expect(failures.otherErrorCount == 0)
    }
}
