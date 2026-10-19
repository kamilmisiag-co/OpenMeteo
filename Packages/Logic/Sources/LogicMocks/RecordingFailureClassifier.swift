//
//  RecordingFailureClassifier.swift
//  LogicMocks
//
//  Created by Kamil Misiag on 19/10/2026.
//

import Logic
import Synchronization

public final class RecordingFailureClassifier: FailureClassifying {
    private let classified: ServiceFailure
    private let received = Mutex<[any Error]>([])

    public init(classifying classified: ServiceFailure) {
        self.classified = classified
    }

    public var receivedErrors: [any Error] {
        received.withLock { $0 }
    }

    public func failure(for error: any Error) -> ServiceFailure {
        received.withLock { $0.append(error) }
        return classified
    }
}
