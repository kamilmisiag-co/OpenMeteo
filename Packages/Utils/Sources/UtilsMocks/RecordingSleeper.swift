//
//  RecordingSleeper.swift
//  UtilsMocks
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Synchronization
import Utils

public final class RecordingSleeper: Sleeping {
    private let recorded = Mutex<[Duration]>([])
    private let checksCancellation: Bool
    private let cancelsTask: Bool
    private let failure: (any Error)?

    public init(checksCancellation: Bool = true, cancelsTask: Bool = false, failure: (any Error)? = nil) {
        self.checksCancellation = checksCancellation
        self.cancelsTask = cancelsTask
        self.failure = failure
    }

    public var durations: [Duration] {
        recorded.withLock { $0 }
    }

    public func sleep(for duration: Duration) async throws {
        recorded.withLock { $0.append(duration) }
        if cancelsTask {
            withUnsafeCurrentTask { $0?.cancel() }
        }
        if let failure {
            throw failure
        }
        if checksCancellation {
            try Task.checkCancellation()
        }
    }
}
