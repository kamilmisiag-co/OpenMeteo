//
//  PreviewOutlooks.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

#if DEBUG
import Logic

nonisolated enum PreviewOutlooks {
    private static let week = Array(0...6)

    static let lisbon: [ActivityOutlook] = [
        outlook(.surfing, scores: [82, 86, 92, 88, 80, 52, 66], factors: [
            Factor(kind: .rain, effect: .hurts, days: [5, 6]),
            Factor(kind: .wind, effect: .hurts, days: [5]),
            Factor(kind: .temperature, effect: .helps, days: week),
        ]),
        outlook(.outdoorSightseeing, scores: [84, 90, 88, 82, 70, 30, 60], factors: [
            Factor(kind: .rain, effect: .hurts, days: [5, 6]),
            Factor(kind: .temperature, effect: .helps, days: week),
            Factor(kind: .wind, effect: .helps, days: Array(0...4)),
        ]),
        outlook(.indoorSightseeing, scores: [40, 36, 38, 42, 52, 76, 52], factors: [
            Factor(kind: .temperature, effect: .hurts, days: Array(0...4)),
            Factor(kind: .rain, effect: .helps, days: [5, 6]),
            Factor(kind: .wind, effect: .helps, days: [5]),
        ]),
        outlook(.skiing, scores: Array(repeating: nil, count: 7), factors: [
            Factor(kind: .snowfall, effect: .hurts, days: week),
            Factor(kind: .temperature, effect: .hurts, days: week),
        ]),
    ]

    static let bergen: [ActivityOutlook] = [
        outlook(.indoorSightseeing, scores: [55, 50, 58, 48, 52, 59, 56], factors: [
            Factor(kind: .rain, effect: .helps, days: week),
        ]),
        outlook(.outdoorSightseeing, scores: [30, 42, 28, 36, 40, 26, 36], factors: [
            Factor(kind: .rain, effect: .hurts, days: week),
        ]),
        outlook(.surfing, scores: [20, 30, 18, 24, 26, 16, 20], factors: [
            Factor(kind: .wind, effect: .hurts, days: week),
            Factor(kind: .rain, effect: .hurts, days: [0, 1, 2, 4, 5, 6]),
        ]),
        outlook(.skiing, scores: Array(repeating: nil, count: 7), factors: [
            Factor(kind: .snowfall, effect: .hurts, days: week),
        ]),
    ]

    private static func outlook(_ activity: Activity, scores: [Int?], factors: [Factor]) -> ActivityOutlook {
        let days = scores.enumerated().map { day, score in
            let effects = effects(onDay: day, from: factors)
            return score.map { DayAssessment(score: $0, effects: effects) } ?? DayAssessment(blockedBy: .snowfall, effects: effects)
        }
        return ActivityOutlook(activity: activity, days: days, factors: factors)
    }

    private static func effects(onDay day: Int, from factors: [Factor]) -> [Factor.Kind: Factor.Effect] {
        Dictionary(
            factors.filter { $0.days.contains(day) }.map { ($0.kind, $0.effect) },
            uniquingKeysWith: { first, _ in first }
        )
    }
}
#endif
