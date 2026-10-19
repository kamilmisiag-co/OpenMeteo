//
//  ActivityInsightBuilder.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public struct ActivityInsightBuilder: ActivityInsightProviding {
    private let ranker: any ActivityRanking

    public init(ranker: any ActivityRanking) {
        self.ranker = ranker
    }

    public func insight(for activity: Activity, in forecast: CityForecast) -> ActivityInsight? {
        let ranking = ranker.rank(forecast.outlooks, onDay: nil)
        guard let ranked = ranking.first(where: { $0.activity == activity }) else { return nil }
        return ActivityInsight(
            outlook: ranked.outlook,
            rank: ranked.rank,
            rankedCount: ranking.count,
            dominantBlocker: ranked.outlook.dominantBlocker
        )
    }
}
