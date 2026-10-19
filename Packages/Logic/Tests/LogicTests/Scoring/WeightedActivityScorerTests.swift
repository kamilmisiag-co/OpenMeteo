//
//  WeightedActivityScorerTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic
import LogicMocks
import Testing
import Utils

@Suite("Weighted activity scorer")
struct WeightedActivityScorerTests {
    private struct StubRule: FactorRule {
        let kind: Factor.Kind
        let weight: Double
        let ratings: [Double?]

        func suitability(ofDay index: Int, in days: [DailyWeather]) -> Double? {
            ratings.element(at: index) ?? nil
        }
    }

    private struct StubBlocker: BlockingRule {
        let kind: Factor.Kind
        let blockedDays: Set<Int>

        func blocks(day index: Int, in days: [DailyWeather]) -> Bool {
            blockedDays.contains(index)
        }
    }

    private let today = [LogicFixtures.day()]
    private let threeDays = LogicFixtures.days(count: 3)

    @Test("Assesses every given day on its own, in order, and nothing more")
    func oneAssessmentPerDay() {
        let rule = StubRule(kind: .wind, weight: 1, ratings: [0.2, 0.9, nil, 0.5])
        let assessments = scorer([rule], blockers: [StubBlocker(kind: .thunderstorm, blockedDays: [1])]).assess(threeDays)
        #expect(assessments == [
            DayAssessment(score: 20, effects: [.wind: .hurts]),
            DayAssessment(blockedBy: .thunderstorm, effects: [.wind: .helps]),
            DayAssessment(score: 0, effects: [:]),
        ])
        #expect(scorer([rule]).assess([]).isEmpty)
    }

    @Test("The score is the weighted mean of the rule ratings")
    func weightedMean() {
        let rules = [
            StubRule(kind: .wind, weight: 0.5, ratings: [1]),
            StubRule(kind: .rain, weight: 0.3, ratings: [0.5]),
            StubRule(kind: .temperature, weight: 0.2, ratings: [0.2]),
        ]
        #expect(scorer(rules).assess(today) == [DayAssessment(score: 69, effects: [.wind: .helps, .temperature: .hurts])])
    }

    @Test("Rules without data are left out and the remaining weights renormalised")
    func missingData() {
        let rules = [
            StubRule(kind: .rain, weight: 0.5, ratings: [nil]),
            StubRule(kind: .wind, weight: 0.25, ratings: [0.8]),
            StubRule(kind: .temperature, weight: 0.25, ratings: [0.4]),
        ]
        #expect(scorer(rules).assess(today) == [DayAssessment(score: 60, effects: [.wind: .helps, .temperature: .hurts])])
    }

    @Test("Without any rating the score is just the baseline")
    func noRatings() {
        let unrated = [StubRule(kind: .wind, weight: 1, ratings: [nil])]
        #expect(scorer([]).assess(today).first?.score == 0)
        #expect(scorer([], baseline: 0.3).assess(today).first?.score == 30)
        #expect(scorer(unrated).assess(today).first?.score == 0)
        #expect(scorer(unrated, baseline: 0.3).assess(today).first?.score == 30)
    }

    @Test("Inverted polarity rates the opposite of every rule, for the score and the effects")
    func invertedPolarity() {
        let rules = [
            StubRule(kind: .wind, weight: 0.5, ratings: [1]),
            StubRule(kind: .rain, weight: 0.3, ratings: [0.5]),
            StubRule(kind: .temperature, weight: 0.2, ratings: [0.2]),
        ]
        #expect(scorer(rules, polarity: .inverted).assess(today) == [DayAssessment(score: 31, effects: [.wind: .hurts, .temperature: .helps])])
    }

    @Test("The baseline lifts the floor and scales the rest of the range")
    func baseline() {
        let rule = StubRule(kind: .wind, weight: 1, ratings: [0.5, 0, 1])
        #expect(scorer([rule], baseline: 0.3).assess(threeDays).map(\.score) == [65, 30, 100])
    }

    @Test("Ratings outside 0...1 are clamped and NaN counts as the worst rating, before any inversion")
    func unboundedRatings() {
        let rules = [
            StubRule(kind: .wind, weight: 1, ratings: [1.4]),
            StubRule(kind: .rain, weight: 1, ratings: [.nan]),
            StubRule(kind: .temperature, weight: 1, ratings: [-0.5]),
        ]
        #expect(scorer(rules).assess(today) == [DayAssessment(score: 33, effects: [.wind: .helps, .rain: .hurts, .temperature: .hurts])])
        #expect(scorer(rules, polarity: .inverted).assess(today) == [DayAssessment(score: 67, effects: [.wind: .hurts, .rain: .helps, .temperature: .helps])])
    }

    @Test("A factor helps from the helping threshold up, hurts below the hurting threshold and is left out in between")
    func effectThresholds() {
        let rules = [
            StubRule(kind: .wind, weight: 1, ratings: [0.75]),
            StubRule(kind: .rain, weight: 1, ratings: [0.5]),
            StubRule(kind: .temperature, weight: 1, ratings: [0.49]),
            StubRule(kind: .snowfall, weight: 1, ratings: [0.6]),
        ]
        #expect(scorer(rules).assess(today).first?.effects == [.wind: .helps, .temperature: .hurts])
    }

    @Test("The injected thresholds decide the effects")
    func customThresholds() {
        let rules = [
            StubRule(kind: .wind, weight: 1, ratings: [0.8]),
            StubRule(kind: .rain, weight: 1, ratings: [0.95]),
            StubRule(kind: .temperature, weight: 1, ratings: [0.1]),
            StubRule(kind: .snowfall, weight: 1, ratings: [0.2]),
        ]
        let thresholds = EffectThresholds(helpsFrom: 0.9, hurtsBelow: 0.2)
        #expect(scorer(rules, thresholds: thresholds).assess(today).first?.effects == [.rain: .helps, .temperature: .hurts])
    }

    @Test("A factor rated by several rules takes its lowest rating, after inversion")
    func lowestRatingPerKind() {
        let wind = [StubRule(kind: .wind, weight: 1, ratings: [0.9]), StubRule(kind: .wind, weight: 1, ratings: [0.3])]
        #expect(scorer(wind).assess(today).first?.effects == [.wind: .hurts])
        let rain = [StubRule(kind: .rain, weight: 1, ratings: [0.2]), StubRule(kind: .rain, weight: 1, ratings: [0.9])]
        #expect(scorer(rain, polarity: .inverted).assess(today).first?.effects == [.rain: .hurts])
    }

    @Test("A blocked day has no score but keeps its effects, with the blocker hurting")
    func blockedDay() {
        let rules = [StubRule(kind: .wind, weight: 1, ratings: [0.9]), StubRule(kind: .snowfall, weight: 1, ratings: [0.9])]
        let assessment = scorer(rules, blockers: [StubBlocker(kind: .snowfall, blockedDays: [0])]).assess(today).first
        #expect(assessment?.score == nil)
        #expect(assessment?.blocker == .snowfall)
        #expect(assessment?.effects == [.wind: .helps, .snowfall: .hurts])
    }

    @Test("The first blocker that blocks the day names it")
    func firstBlockerWins() {
        let blockers = [
            StubBlocker(kind: .wind, blockedDays: []),
            StubBlocker(kind: .thunderstorm, blockedDays: [0]),
            StubBlocker(kind: .snowfall, blockedDays: [0]),
        ]
        #expect(scorer([], blockers: blockers).assess(today) == [DayAssessment(blockedBy: .thunderstorm, effects: [:])])
    }

    private func scorer(
        _ rules: [any FactorRule],
        blockers: [any BlockingRule] = [],
        polarity: ScoringPolarity = .direct,
        baseline: Double = 0,
        thresholds: EffectThresholds = EffectThresholds(helpsFrom: 0.75, hurtsBelow: 0.5)
    ) -> WeightedActivityScorer {
        WeightedActivityScorer(
            activity: .surfing,
            rules: rules,
            blockers: blockers,
            polarity: polarity,
            baseline: baseline,
            effectThresholds: thresholds
        )
    }
}
