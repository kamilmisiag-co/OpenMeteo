//
//  ErrorFailureClassifier.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Utils

public protocol FailureClassifying: Sendable {
    func failure(for error: any Error) -> ServiceFailure
}

public struct ErrorFailureClassifier: FailureClassifying {
    public init() {}

    public func failure(for error: any Error) -> ServiceFailure {
        if (error as? ForecastError) == .noUpcomingDays { return .noUpcomingDays }
        return error.isConnectivity ? .offline : .unavailable
    }
}
