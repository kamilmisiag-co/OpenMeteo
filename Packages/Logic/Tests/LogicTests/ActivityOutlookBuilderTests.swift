//
//  ActivityOutlookBuilderTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic
import Testing

@Suite("Activity outlook builder")
struct ActivityOutlookBuilderTests {
    private struct FixedScorer: ActivityScoring {
        let activity: Activity
        let assessments: [DayAssessment]

        func assess(_ days: [DailyWeather]) -> [DayAssessment] {
            assessments
        }
    }

    private struct HighTemperatureScorer: ActivityScoring {
        let activity: Activity

        func assess(_ days: [DailyWeather]) -> [DayAssessment] {
            days.map { .scored(Int($0.highCelsius), effects: [:]) }
        }
    }

    private let threeDays = Fixtures.week(startingOn: Fixtures.referenceNow, in: "Europe/Lisbon", count: 3)

    @Test("Builds one outlook per scorer, in scorer order")
    func scorerOrder() {
        let builder = ActivityOutlookBuilder(scorers: [
            HighTemperatureScorer(activity: .surfing),
            HighTemperatureScorer(activity: .skiing),
            HighTemperatureScorer(activity: .indoorSightseeing),
        ])
        #expect(builder.outlooks(for: threeDays).map(\.activity) == [.surfing, .skiing, .indoorSightseeing])
    }

    @Test("Keeps only the first scorer for an activity")
    func duplicateActivities() {
        let builder = ActivityOutlookBuilder(scorers: [
            FixedScorer(activity: .surfing, assessments: [.scored(10, effects: [:])]),
            FixedScorer(activity: .skiing, assessments: [.scored(20, effects: [:])]),
            FixedScorer(activity: .surfing, assessments: [.scored(90, effects: [:])]),
        ])
        let outlooks = builder.outlooks(for: threeDays)
        #expect(outlooks.map(\.activity) == [.surfing, .skiing])
        #expect(outlooks.first?.dailyScores == [10])
    }

    @Test("No scorers means no outlooks")
    func noScorers() {
        #expect(ActivityOutlookBuilder(scorers: []).outlooks(for: threeDays).isEmpty)
    }

    @Test("Each outlook holds the scorer's assessment of the given days")
    func assessesGivenDays() {
        let days = [Fixtures.day(high: 18), Fixtures.day(high: 25), Fixtures.day(high: 31)]
        let outlooks = ActivityOutlookBuilder(scorers: [HighTemperatureScorer(activity: .outdoorSightseeing)]).outlooks(for: days)
        #expect(outlooks.map(\.dailyScores) == [[18, 25, 31]])
    }

    @Test("Assessments beyond the given days are dropped, along with their factors")
    func truncatesToDayCount() {
        let assessments: [DayAssessment] = [
            .scored(60, effects: [.wind: .helps]),
            .scored(70, effects: [:]),
            .scored(80, effects: [.rain: .hurts]),
            .scored(90, effects: [.wind: .hurts]),
        ]
        let builder = ActivityOutlookBuilder(scorers: [FixedScorer(activity: .surfing, assessments: assessments)])
        let outlook = builder.outlooks(for: Array(threeDays.prefix(2))).first
        #expect(outlook?.days == Array(assessments.prefix(2)))
        #expect(outlook?.factors == [Factor(kind: .wind, effect: .helps, days: [0])])
    }

    @Test("A scorer that returns fewer assessments than days keeps what it returned")
    func shortAssessments() {
        let builder = ActivityOutlookBuilder(scorers: [FixedScorer(activity: .skiing, assessments: [.scored(55, effects: [:])])])
        #expect(builder.outlooks(for: threeDays).first?.dailyScores == [55])
    }

    @Test("A factor that hurts on any day reports only the days it hurts")
    func hurtingFactorWins() {
        let factors = reportedFactors(for: [
            .scored(80, effects: [.wind: .helps]),
            .scored(40, effects: [.wind: .hurts]),
            .scored(30, effects: [.wind: .hurts]),
        ])
        #expect(factors == [Factor(kind: .wind, effect: .hurts, days: [1, 2])])
    }

    @Test("A factor that only helps reports the days it helps")
    func helpingFactor() {
        let factors = reportedFactors(for: [
            .scored(80, effects: [.rain: .helps]),
            .scored(70, effects: [:]),
            .scored(90, effects: [.rain: .helps]),
        ])
        #expect(factors == [Factor(kind: .rain, effect: .helps, days: [0, 2])])
    }

    @Test("A blocked day counts as a hurting day for its blocker")
    func blockedDay() {
        let factors = reportedFactors(for: [
            .scored(80, effects: [:]),
            .blocked(by: .thunderstorm, effects: [.thunderstorm: .helps]),
        ])
        #expect(factors == [Factor(kind: .thunderstorm, effect: .hurts, days: [1])])
    }

    @Test("Days without effects produce no factors")
    func noEffects() {
        #expect(reportedFactors(for: [.scored(80, effects: [:]), .scored(60, effects: [:])]).isEmpty)
        #expect(reportedFactors(for: []).isEmpty)
    }

    @Test("Hurting factors come before helping ones, then the ones affecting more days, then the kind order")
    func factorOrder() {
        let factors = reportedFactors(for: [
            .scored(50, effects: [.wind: .helps, .rain: .hurts, .temperature: .hurts, .snowfall: .helps]),
            .scored(50, effects: [.wind: .helps, .temperature: .hurts, .thunderstorm: .hurts]),
            .scored(50, effects: [.wind: .helps, .snowfall: .helps]),
        ])
        #expect(factors == [
            Factor(kind: .temperature, effect: .hurts, days: [0, 1]),
            Factor(kind: .rain, effect: .hurts, days: [0]),
            Factor(kind: .thunderstorm, effect: .hurts, days: [1]),
            Factor(kind: .wind, effect: .helps, days: [0, 1, 2]),
            Factor(kind: .snowfall, effect: .helps, days: [0, 2]),
        ])
    }

    @Test("Equal factors keep the kind order")
    func kindOrderOnTies() {
        let factors = reportedFactors(for: [
            .scored(50, effects: [.snowfall: .hurts, .thunderstorm: .hurts, .temperature: .hurts, .rain: .hurts, .wind: .hurts]),
        ])
        #expect(factors.map(\.kind) == Factor.Kind.allCases)
    }

    private func reportedFactors(for assessments: [DayAssessment]) -> [Factor] {
        let days = Fixtures.week(startingOn: Fixtures.referenceNow, in: "Europe/Lisbon", count: assessments.count)
        let builder = ActivityOutlookBuilder(scorers: [FixedScorer(activity: .surfing, assessments: assessments)])
        return builder.outlooks(for: days).first?.factors ?? []
    }
}
