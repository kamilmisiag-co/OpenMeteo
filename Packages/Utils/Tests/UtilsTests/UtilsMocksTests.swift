//
//  UtilsMocksTests.swift
//  UtilsTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Testing
import Utils
import UtilsMocks

@Suite("Recording sleeper")
struct RecordingSleeperTests {
    private let sleeper = RecordingSleeper()

    @Test("A new sleeper has recorded nothing")
    func startsEmpty() {
        #expect(sleeper.durations.isEmpty)
    }

    @Test("Sleeps return at once and are recorded in the order they were requested")
    func recordsInOrder() async throws {
        let elapsed = try await ContinuousClock().measure {
            try await sleeper.sleep(for: .seconds(60))
            try await sleeper.sleep(for: .milliseconds(900))
            try await sleeper.sleep(for: .zero)
            try await sleeper.sleep(for: .milliseconds(900))
        }
        #expect(elapsed < .milliseconds(500))
        #expect(sleeper.durations == [.seconds(60), .milliseconds(900), .zero, .milliseconds(900)])
    }

    @Test("A sleep in a cancelled task is recorded and then throws a cancellation error")
    func cancellation() async {
        let task = Task { [sleeper] in
            withUnsafeCurrentTask { $0?.cancel() }
            try await sleeper.sleep(for: .seconds(3))
        }
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(sleeper.durations == [.seconds(3)])
    }
}

@Suite("Manual date provider")
struct ManualDateProviderTests {
    private let start = Date(timeIntervalSinceReferenceDate: 800_000_000)

    @Test("The date stays at the injected value until it is changed")
    func now() {
        let provider = ManualDateProvider(now: start)
        #expect(provider.now() == start)
        #expect(provider.now() == start)
    }

    @Test("Setting a date replaces the current one, even with an earlier date")
    func set() {
        let provider = ManualDateProvider(now: start)
        let later = start.addingTimeInterval(3_600)
        provider.set(later)
        #expect(provider.now() == later)
        let earlier = start.addingTimeInterval(-86_400)
        provider.set(earlier)
        #expect(provider.now() == earlier)
    }

    @Test("Advancing adds the duration to the current date, sub-second parts included")
    func advance() {
        let provider = ManualDateProvider(now: start)
        provider.advance(by: .seconds(90))
        #expect(provider.now() == start.addingTimeInterval(90))
        provider.advance(by: .milliseconds(250))
        #expect(provider.now() == start.addingTimeInterval(90.25))
        provider.advance(by: .milliseconds(1_500))
        #expect(provider.now() == start.addingTimeInterval(91.75))
        provider.advance(by: .zero)
        #expect(provider.now() == start.addingTimeInterval(91.75))
    }

    @Test("Advancing continues from a date that was set")
    func advanceAfterSet() {
        let provider = ManualDateProvider(now: start)
        let later = start.addingTimeInterval(600)
        provider.set(later)
        provider.advance(by: .milliseconds(500))
        #expect(provider.now() == later.addingTimeInterval(0.5))
    }
}
