//
//  ManualClock.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Synchronization
import Utils

final class ManualClock: DateProviding {
    private let current: Mutex<Date>

    init(now: Date) {
        current = Mutex(now)
    }

    func now() -> Date {
        current.withLock { $0 }
    }

    func advance(by interval: TimeInterval) {
        current.withLock { $0 = $0.addingTimeInterval(interval) }
    }
}
