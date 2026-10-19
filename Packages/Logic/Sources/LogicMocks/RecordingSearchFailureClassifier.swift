//
//  RecordingSearchFailureClassifier.swift
//  LogicMocks
//
//  Created by Kamil Misiag on 19/10/2026.
//

import Logic
import Synchronization

public final class RecordingSearchFailureClassifier: SearchFailureClassifying {
    private let classified: SearchFailure
    private let received = Mutex<[any Error]>([])

    public init(failure: SearchFailure) {
        classified = failure
    }

    public var receivedErrors: [any Error] {
        received.withLock { $0 }
    }

    public func failure(for error: any Error) -> SearchFailure {
        received.withLock { $0.append(error) }
        return classified
    }
}
