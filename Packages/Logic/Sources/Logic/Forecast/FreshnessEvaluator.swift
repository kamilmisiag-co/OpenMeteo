//
//  FreshnessEvaluator.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation

public struct FreshnessEvaluator: FreshnessEvaluating {
    private let staleAfter: Duration

    public init(staleAfter: Duration) {
        self.staleAfter = staleAfter
    }

    public func freshness(of result: ForecastResult, at now: Date) -> Freshness {
        let fetchedAt = result.forecast.fetchedAt
        return switch result.origin {
        case .cache: .offline(since: fetchedAt)
        case .live where now.timeIntervalSince(fetchedAt) > staleAfter / .seconds(1): .stale(since: fetchedAt)
        case .live: .fresh
        }
    }
}
