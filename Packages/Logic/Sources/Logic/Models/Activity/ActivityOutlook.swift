//
//  ActivityOutlook.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Utils

public struct ActivityOutlook: Hashable, Sendable {
    public let activity: Activity
    public let days: [DayAssessment]
    public let factors: [Factor]

    public init(activity: Activity, days: [DayAssessment], factors: [Factor]) {
        self.activity = activity
        self.days = days
        self.factors = factors
    }

    public var dailyScores: [Int?] {
        days.map(\.score)
    }

    public var weeklyScore: Int? {
        let scores = dailyScores
        guard scores.contains(where: { $0 != nil }) else { return nil }
        let total = scores.sum { $0 ?? 0 }
        return Int((Double(total) / Double(scores.count)).rounded())
    }

    public var bestDay: DayScore? {
        var best: DayScore?
        for (day, score) in dailyScores.enumerated() {
            guard let score, score > best?.score ?? Int.min else { continue }
            best = DayScore(day: day, score: score)
        }
        return best
    }

    public var dominantBlocker: Factor.Kind? {
        days.compactMap(\.blocker).mostFrequentCase()
    }

    public func score(onDay day: Int) -> Int? {
        days.element(at: day)?.score
    }
}
