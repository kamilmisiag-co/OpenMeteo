//
//  ScriptedFreshnessEvaluator.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic
import Synchronization

final class ScriptedFreshnessEvaluator: FreshnessEvaluating {
    struct Call: Hashable, Sendable {
        let result: ForecastResult
        let now: Date
    }

    private let scripted: Freshness
    private let recorded = Mutex<[Call]>([])

    init(freshness: Freshness) {
        scripted = freshness
    }

    var calls: [Call] {
        recorded.withLock { $0 }
    }

    func freshness(of result: ForecastResult, at now: Date) -> Freshness {
        recorded.withLock { $0.append(Call(result: result, now: now)) }
        return scripted
    }
}
