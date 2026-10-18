//
//  TaskDelayerTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic
import Testing

@Suite("Task delayer")
struct TaskDelayerTests {
    private let delayer = TaskDelayer()

    @Test("A zero-length delay returns without throwing")
    func zeroDelay() async throws {
        try await delayer.delay(for: .zero)
    }

    @Test("A delay waits at least the requested duration")
    func waitsForDuration() async throws {
        let requested = Duration.milliseconds(20)
        let elapsed = try await ContinuousClock().measure {
            try await delayer.delay(for: requested)
        }
        #expect(elapsed >= requested)
    }

    @Test("A delay in a cancelled task throws a cancellation error instead of waiting")
    func cancellation() async {
        let task = Task { [delayer] in
            withUnsafeCurrentTask { $0?.cancel() }
            try await delayer.delay(for: .seconds(60))
        }
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }
}
