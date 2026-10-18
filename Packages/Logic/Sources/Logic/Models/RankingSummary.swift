//
//  RankingSummary.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public struct RankingSummary: Hashable, Sendable {
    public let ranking: [RankedActivity]
    public let selectedDay: Int?
    public let hasStrongTopPick: Bool

    public init(ranking: [RankedActivity], selectedDay: Int?, hasStrongTopPick: Bool) {
        self.ranking = ranking
        self.selectedDay = selectedDay
        self.hasStrongTopPick = hasStrongTopPick
    }

    public var topPick: RankedActivity? {
        ranking.first
    }

    public var others: [RankedActivity] {
        Array(ranking.dropFirst())
    }

    public var topPickBestDayOfWeek: DayScore? {
        guard let topPick, topPick.isSuitable else { return nil }
        return topPick.outlook.bestDay
    }
}
