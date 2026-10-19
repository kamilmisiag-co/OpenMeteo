//
//  RankingSummarizer.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public protocol RankingSummarizing: Sendable {
    func summary(of forecast: CityForecast, onDay day: Int?) -> RankingSummary
}

public struct RankingSummarizer: RankingSummarizing {
    private let ranker: any ActivityRanking
    private let strongScoreThreshold: Int

    public init(ranker: any ActivityRanking, strongScoreThreshold: Int) {
        self.ranker = ranker
        self.strongScoreThreshold = strongScoreThreshold
    }

    public func summary(of forecast: CityForecast, onDay day: Int?) -> RankingSummary {
        let ranking = ranker.rank(forecast.outlooks, onDay: day)
        return RankingSummary(ranking: ranking, selectedDay: day, hasStrongTopPick: isStrong(ranking.first))
    }

    private func isStrong(_ topPick: RankedActivity?) -> Bool {
        guard let score = topPick?.score else { return false }
        return score >= strongScoreThreshold
    }
}
