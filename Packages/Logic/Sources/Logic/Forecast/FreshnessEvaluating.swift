//
//  FreshnessEvaluating.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation

public protocol FreshnessEvaluating: Sendable {
    func freshness(of result: ForecastResult, at now: Date) -> Freshness
}
