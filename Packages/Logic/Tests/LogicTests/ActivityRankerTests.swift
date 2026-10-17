//
//  ActivityRankerTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic
import Testing

@Suite("Activity ranker")
struct ActivityRankerTests {
    private let ranker = ActivityRanker(tieBreakOrder: [.surfing, .outdoorSightseeing, .indoorSightseeing, .skiing])

    @Test("Ranks by weekly score, highest first, carrying the score used")
    func weeklyRanking() {
        let ranked = ranker.rank([
            outlook(.surfing, scores: [50, 50]),
            outlook(.skiing, scores: [90, 90]),
            outlook(.indoorSightseeing, scores: [70, 70]),
        ], onDay: nil)
        #expect(ranked.map(\.activity) == [.skiing, .indoorSightseeing, .surfing])
        #expect(ranked.map(\.rank) == [1, 2, 3])
        #expect(ranked.map(\.score) == [90, 70, 50])
    }

    @Test("Ranks by the score on the chosen day")
    func dayRanking() {
        let ranked = ranker.rank([
            outlook(.skiing, scores: [90, 10]),
            outlook(.surfing, scores: [10, 60]),
        ], onDay: 1)
        #expect(ranked.map(\.activity) == [.surfing, .skiing])
        #expect(ranked.map(\.score) == [60, 10])
    }

    @Test("Unsuitable activities rank after every suitable one")
    func unsuitableLast() {
        let ranked = ranker.rank([
            outlook(.surfing, scores: [nil, nil]),
            outlook(.skiing, scores: [5, nil]),
        ], onDay: nil)
        #expect(ranked.map(\.activity) == [.skiing, .surfing])
        #expect(ranked.map(\.score) == [3, nil])
        #expect(ranked.map(\.isSuitable) == [true, false])
    }

    @Test("A day outside the outlooks leaves every activity unscored in tie-break order")
    func dayOutOfRange() {
        let ranked = ranker.rank([
            outlook(.skiing, scores: [90]),
            outlook(.indoorSightseeing, scores: [80]),
            outlook(.surfing, scores: [70]),
        ], onDay: 4)
        #expect(ranked.map(\.activity) == [.surfing, .indoorSightseeing, .skiing])
        #expect(ranked.map(\.score) == [nil, nil, nil])
        #expect(ranked.map(\.rank) == [1, 2, 3])
    }

    @Test("Equal scores put the activity with the better best day first")
    func bestDayBreaksTies() {
        let ranked = ranker.rank([
            outlook(.surfing, scores: [50, 50]),
            outlook(.skiing, scores: [100, 0]),
        ], onDay: nil)
        #expect(ranked.map(\.activity) == [.skiing, .surfing])
        #expect(ranked.map(\.score) == [50, 50])
    }

    @Test("Equal scores on the chosen day put the activity with the better best day of the week first")
    func bestDayBreaksDayTies() {
        let ranked = ranker.rank([
            outlook(.surfing, scores: [50, 60]),
            outlook(.skiing, scores: [50, 90]),
        ], onDay: 0)
        #expect(ranked.map(\.activity) == [.skiing, .surfing])
        #expect(ranked.map(\.score) == [50, 50])
    }

    @Test("Equal scores and best days fall back to the tie-break order")
    func tieBreakOrder() {
        let ranked = ranker.rank([
            outlook(.skiing, scores: [60, 60]),
            outlook(.indoorSightseeing, scores: [60, 60]),
            outlook(.outdoorSightseeing, scores: [60, 60]),
            outlook(.surfing, scores: [60, 60]),
        ], onDay: nil)
        #expect(ranked.map(\.activity) == [.surfing, .outdoorSightseeing, .indoorSightseeing, .skiing])
    }

    @Test("Activities missing from the tie-break order follow the listed ones in declaration order")
    func unlistedActivities() {
        let ranker = ActivityRanker(tieBreakOrder: [.indoorSightseeing])
        let ranked = ranker.rank(Activity.allCases.reversed().map { outlook($0, scores: [40]) }, onDay: nil)
        #expect(ranked.map(\.activity) == [.indoorSightseeing, .skiing, .surfing, .outdoorSightseeing])
    }

    @Test("Unscored activities ignore their best day and follow the tie-break order")
    func unscoredIgnoreBestDay() {
        let ranked = ranker.rank([
            outlook(.skiing, scores: [nil, 100]),
            outlook(.surfing, scores: [nil, 10]),
        ], onDay: 0)
        #expect(ranked.map(\.activity) == [.surfing, .skiing])
    }

    @Test("The input order doesn't change the ranking")
    func inputOrderIndependent() {
        let outlooks = [
            outlook(.skiing, scores: [60, 60]),
            outlook(.surfing, scores: [80, nil]),
            outlook(.indoorSightseeing, scores: [nil, nil]),
            outlook(.outdoorSightseeing, scores: [40, 80]),
        ]
        let expected: [Activity] = [.outdoorSightseeing, .skiing, .surfing, .indoorSightseeing]
        #expect(ranker.rank(outlooks, onDay: nil).map(\.activity) == expected)
        #expect(ranker.rank(outlooks.reversed(), onDay: nil).map(\.activity) == expected)
    }

    @Test("Nothing to rank gives an empty ranking")
    func empty() {
        #expect(ranker.rank([], onDay: nil).isEmpty)
        #expect(ranker.rank([], onDay: 0).isEmpty)
    }

    private func outlook(_ activity: Activity, scores: [Int?]) -> ActivityOutlook {
        let days = scores.map { score in
            score.map { DayAssessment.scored($0, effects: [:]) } ?? .blocked(by: .rain, effects: [:])
        }
        return ActivityOutlook(activity: activity, days: days, factors: [])
    }
}
