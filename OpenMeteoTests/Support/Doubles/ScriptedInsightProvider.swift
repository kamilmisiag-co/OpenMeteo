//
//  ScriptedInsightProvider.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic
import Synchronization

final class ScriptedInsightProvider: ActivityInsightProviding {
    struct Call: Hashable, Sendable {
        let activity: Activity
        let forecast: CityForecast
    }

    private let insights: [Activity: ActivityInsight]
    private let recorded = Mutex<[Call]>([])

    init(insights: [Activity: ActivityInsight] = [:]) {
        self.insights = insights
    }

    var calls: [Call] {
        recorded.withLock { $0 }
    }

    func insight(for activity: Activity, in forecast: CityForecast) -> ActivityInsight? {
        recorded.withLock { $0.append(Call(activity: activity, forecast: forecast)) }
        return insights[activity]
    }
}
