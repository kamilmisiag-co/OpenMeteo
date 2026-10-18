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

    public init() {}

    public var durations: [Duration] {
        recorded.withLock { $0 }
    }

    public func sleep(for duration: Duration) async throws {
        recorded.withLock { $0.append(duration) }
        try Task.checkCancellation()
    }
}
