//
//  ControlledSleeper.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Synchronization
import Utils

final class ControlledSleeper: Sleeping {
    private struct Sleeps {
        var durations: [Duration] = []
        var nextID = 0
        var pending: [Int: CheckedContinuation<Void, any Error>] = [:]
        var cancelled: Set<Int> = []
    }

    private let sleeps = Mutex(Sleeps())

    var durations: [Duration] {
        sleeps.withLock { $0.durations }
    }

    var pendingCount: Int {
        sleeps.withLock { $0.pending.count }
    }

    func sleep(for duration: Duration) async throws {
        let id = sleeps.withLock { sleeps in
            sleeps.durations.append(duration)
            sleeps.nextID += 1
            return sleeps.nextID
        }
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let isCancelled = sleeps.withLock { sleeps in
                    guard sleeps.cancelled.remove(id) == nil else { return true }
                    sleeps.pending[id] = continuation
                    return false
                }
                if isCancelled {
                    continuation.resume(throwing: CancellationError())
                }
            }
        } onCancel: {
            let continuation = sleeps.withLock { sleeps in
                guard let continuation = sleeps.pending.removeValue(forKey: id) else {
                    sleeps.cancelled.insert(id)
                    return CheckedContinuation<Void, any Error>?.none
                }
                return continuation
            }
            continuation?.resume(throwing: CancellationError())
        }
    }

    func wakeAll() {
        let continuations = sleeps.withLock { sleeps in
            let continuations = Array(sleeps.pending.values)
            sleeps.pending = [:]
            return continuations
        }
        continuations.forEach { $0.resume() }
    }
}
