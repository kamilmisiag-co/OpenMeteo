//
//  TaskSleeperTests.swift
//  UtilsTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Testing
import Utils

@Suite("Task sleeper")
struct TaskSleeperTests {
    private let sleeper = TaskSleeper()

    @Test("A zero-length sleep returns without throwing")
    func zeroSleep() async throws {
        try await sleeper.sleep(for: .zero)
    }

    @Test("A sleep waits at least the requested duration")
    func waitsForDuration() async throws {
        let requested = Duration.milliseconds(20)
        let elapsed = try await ContinuousClock().measure {
            try await sleeper.sleep(for: requested)
        }
        #expect(elapsed >= requested)
    }

    @Test("A sleep in a cancelled task throws a cancellation error instead of waiting")
    func cancellation() async {
        let task = Task { [sleeper] in
            withUnsafeCurrentTask { $0?.cancel() }
            try await sleeper.sleep(for: .seconds(60))
        }
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }
}
