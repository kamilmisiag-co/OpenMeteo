//
//  RecordingDetailPresenter.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic
@testable import OpenMeteo

@MainActor
final class RecordingDetailPresenter: ActivityDetailPresenting {
    struct Request: Hashable {
        let insight: ActivityInsight
        let forecast: CityForecast
        let freshness: Freshness
        let now: Date
    }

    private(set) var requests: [Request] = []

    func detail(for insight: ActivityInsight, in forecast: CityForecast, freshness: Freshness, now: Date) -> ActivityDetail {
        let request = Request(insight: insight, forecast: forecast, freshness: freshness, now: now)
        requests.append(request)
        return Self.labelledDetail(for: request)
    }

    static func labelledDetail(for request: Request) -> ActivityDetail {
        ActivityDetail(
            subtitle: request.forecast.city.name,
            score: request.insight.weeklyScore,
            rank: "\(request.insight.rank)/\(request.insight.rankedCount)",
            reason: request.insight.activity.rawValue,
            bestDay: "fetched \(RecordingRankingPresenter.seconds(request.forecast.fetchedAt))",
            bars: [],
            emptyChart: nil,
            days: [],
            factors: [],
            scoringNote: "now \(RecordingRankingPresenter.seconds(request.now))",
            banner: RecordingRankingPresenter.labelledBanner(for: request.freshness)
        )
    }
}
