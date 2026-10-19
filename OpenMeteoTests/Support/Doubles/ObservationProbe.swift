//
//  ObservationProbe.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Observation
import Synchronization

final class ObservationProbe: Sendable {
    private let changes = Mutex(0)

    var changeCount: Int {
        changes.withLock { $0 }
    }

    func track(_ access: () -> Void) {
        withObservationTracking(access) { [self] in
            changes.withLock { $0 += 1 }
        }
    }
}
