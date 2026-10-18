//
//  ErrorSearchFailureClassifier.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Utils

public struct ErrorSearchFailureClassifier: SearchFailureClassifying {
    public init() {}

    public func failure(for error: any Error) -> SearchFailure {
        error.isConnectivity ? .offline : .unavailable
    }
}
