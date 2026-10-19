//
//  ScriptedRankingSummarizer.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic
import Synchronization

final class ScriptedRankingSummarizer: RankingSummarizing {
    struct Call: Hashable, Sendable {
        let forecast: CityForecast
        let day: Int?
    }

    private let scripted: RankingSummary
    private let recorded = Mutex<[Call]>([])

    init(summary: RankingSummary) {
        scripted = summary
    }

    var calls: [Call] {
        recorded.withLock { $0 }
    }

    func summary(of forecast: CityForecast, onDay day: Int?) -> RankingSummary {
        recorded.withLock { $0.append(Call(forecast: forecast, day: day)) }
        return scripted
    }
}
