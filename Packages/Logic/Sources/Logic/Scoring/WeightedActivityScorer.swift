//
//  WeightedActivityScorer.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Utils

public protocol ActivityScoring: Sendable {
    var activity: Activity { get }

    func assess(_ days: [DailyWeather]) -> [DayAssessment]
}

public struct WeightedActivityScorer: ActivityScoring {
    private struct Rating {
        let kind: Factor.Kind
        let weight: Double
        let suitability: Double
    }

    public let activity: Activity
    private let rules: [any FactorRule]
    private let blockers: [any BlockingRule]
    private let polarity: ScoringPolarity
    private let baseline: Double
    private let effectThresholds: EffectThresholds

    public init(
        activity: Activity,
        rules: [any FactorRule],
        blockers: [any BlockingRule],
        polarity: ScoringPolarity,
        baseline: Double,
        effectThresholds: EffectThresholds
    ) {
        self.activity = activity
        self.rules = rules
        self.blockers = blockers
        self.polarity = polarity
        self.baseline = baseline
        self.effectThresholds = effectThresholds
    }

    public func assess(_ days: [DailyWeather]) -> [DayAssessment] {
        days.indices.map { assessment(ofDay: $0, in: days) }
    }

    private func assessment(ofDay index: Int, in days: [DailyWeather]) -> DayAssessment {
        let ratings = rules.compactMap { rating(by: $0, ofDay: index, in: days) }
        guard let blocker = blockers.first(where: { $0.blocks(day: index, in: days) }) else {
            return DayAssessment(score: score(of: ratings), effects: effects(of: ratings))
        }
        return DayAssessment(blockedBy: blocker.kind, effects: effects(of: ratings))
    }

    private func rating(by rule: any FactorRule, ofDay index: Int, in days: [DailyWeather]) -> Rating? {
        guard let suitability = rule.suitability(ofDay: index, in: days) else { return nil }
        let bounded = suitability.clamped(to: 0...1, ifNaN: 0)
        let adjusted = switch polarity {
        case .direct: bounded
        case .inverted: 1 - bounded
        }
        return Rating(kind: rule.kind, weight: rule.weight, suitability: adjusted)
    }

    private func effects(of ratings: [Rating]) -> [Factor.Kind: Factor.Effect] {
        Dictionary(ratings.map { ($0.kind, $0.suitability) }, uniquingKeysWith: min)
            .compactMapValues(effect(of:))
    }

    private func effect(of suitability: Double) -> Factor.Effect? {
        if suitability >= effectThresholds.helpsFrom { return .helps }
        if suitability < effectThresholds.hurtsBelow { return .hurts }
        return nil
    }

    private func score(of ratings: [Rating]) -> Int {
        let totalWeight = ratings.sum(of: \.weight)
        let weightedSum = ratings.sum { $0.weight * $0.suitability }
        let mean = (weightedSum / totalWeight).finiteValue ?? 0
        let level = baseline + (1 - baseline) * mean
        return Int((100 * level).rounded())
    }
}
