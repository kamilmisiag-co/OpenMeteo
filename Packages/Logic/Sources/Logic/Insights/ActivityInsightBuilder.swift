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
            dominantBlocker: dominantBlocker(in: ranked.outlook)
        )
    }

    private func dominantBlocker(in outlook: ActivityOutlook) -> Factor.Kind? {
        let blockers = outlook.days.compactMap(\.blocker)
        var dominant: Factor.Kind?
        var dominantCount = 0
        for kind in Factor.Kind.allCases {
            let count = blockers.count { $0 == kind }
            if count > dominantCount {
                dominant = kind
                dominantCount = count
            }
        }
        return dominant
    }
}
