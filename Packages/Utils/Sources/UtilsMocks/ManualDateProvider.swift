//
//  ManualDateProvider.swift
//  UtilsMocks
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Synchronization
import Utils

public final class ManualDateProvider: DateProviding {
    private let date: Mutex<Date>

    public init(now: Date) {
        date = Mutex(now)
    }

    public func now() -> Date {
        date.withLock { $0 }
    }

    public func set(_ newDate: Date) {
        date.withLock { $0 = newDate }
    }

    public func advance(by duration: Duration) {
        date.withLock { $0 = $0.addingTimeInterval(duration / .seconds(1)) }
    }
}
