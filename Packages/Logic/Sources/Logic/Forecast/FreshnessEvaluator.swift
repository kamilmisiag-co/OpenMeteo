//
//  FreshnessEvaluator.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Utils

public protocol FreshnessEvaluating: Sendable {
    func freshness(of result: ForecastResult, at now: Date) -> Freshness
}

public struct FreshnessEvaluator: FreshnessEvaluating {
    private let staleAfter: Duration

    public init(staleAfter: Duration) {
        self.staleAfter = staleAfter
    }

    public func freshness(of result: ForecastResult, at now: Date) -> Freshness {
        let fetchedAt = result.forecast.fetchedAt
        return switch result.origin {
        case .cache: .offline(since: fetchedAt)
        case .live where now.timeIntervalSince(fetchedAt) > staleAfter.timeInterval: .stale(since: fetchedAt)
        case .live: .fresh
        }
    }
}
