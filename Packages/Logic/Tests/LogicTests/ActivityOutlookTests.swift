//
//  ActivityOutlookTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic
import Testing

@Suite("Activity outlook")
struct ActivityOutlookTests {
    @Test("Daily scores follow the days with nil for unsuitable days")
    func dailyScores() {
        #expect(outlook(scores: [80, nil, 40]).dailyScores == [80, nil, 40])
        #expect(outlook(scores: []).dailyScores.isEmpty)
    }

    @Test("The weekly score is the rounded mean of every day, counting unsuitable days as zero")
    func weeklyScore() {
        #expect(outlook(scores: [80, 60, 70]).weeklyScore == 70)
        #expect(outlook(scores: [80, nil, 41]).weeklyScore == 40)
        #expect(outlook(scores: [100, nil, nil, nil]).weeklyScore == 25)
        #expect(outlook(scores: [81, 80]).weeklyScore == 81)
        #expect(outlook(scores: [0, nil]).weeklyScore == 0)
    }

    @Test("There's no weekly score without a single suitable day")
    func noWeeklyScore() {
        #expect(outlook(scores: [nil, nil, nil]).weeklyScore == nil)
        #expect(outlook(scores: []).weeklyScore == nil)
    }

    @Test("The best day is the highest score, and the earliest one on ties")
    func bestDay() {
        #expect(outlook(scores: [40, nil, 90, 75]).bestDay == DayScore(day: 2, score: 90))
        #expect(outlook(scores: [nil, 60, 90, 90]).bestDay == DayScore(day: 2, score: 90))
        #expect(outlook(scores: [nil, 0]).bestDay == DayScore(day: 1, score: 0))
    }

    @Test("There's no best day without a suitable day")
    func noBestDay() {
        #expect(outlook(scores: [nil, nil]).bestDay == nil)
        #expect(outlook(scores: []).bestDay == nil)
    }

    @Test("The score on a day is that day's score, and nil outside the outlook")
    func scoreOnDay() {
        let week = outlook(scores: [70, nil, 35])
        #expect(week.score(onDay: 0) == 70)
        #expect(week.score(onDay: 1) == nil)
        #expect(week.score(onDay: 2) == 35)
        #expect(week.score(onDay: 3) == nil)
        #expect(week.score(onDay: -1) == nil)
    }

    private func outlook(scores: [Int?]) -> ActivityOutlook {
        let days = scores.map { score in
            score.map { DayAssessment.scored($0, effects: [:]) } ?? .blocked(by: .wind, effects: [:])
        }
        return ActivityOutlook(activity: .surfing, days: days, factors: [])
    }
}
