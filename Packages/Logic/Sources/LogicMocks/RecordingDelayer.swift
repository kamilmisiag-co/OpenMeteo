//
//  RecordingDelayer.swift
//  LogicMocks
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic
import Synchronization

public final class RecordingDelayer: Delaying {
    private let recorded = Mutex<[Duration]>([])

    public init() {}

    public var durations: [Duration] {
        recorded.withLock { $0 }
    }

    public func delay(for duration: Duration) async throws {
        recorded.withLock { $0.append(duration) }
        try Task.checkCancellation()
    }
}
