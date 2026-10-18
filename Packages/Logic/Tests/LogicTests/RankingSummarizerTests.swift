//
//  RankingSummarizerTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic
import Synchronization
import Testing

@Suite("Ranking summarizer")
struct RankingSummarizerTests {
    private final class RecordingRanker: ActivityRanking {
        struct Request: Equatable {
            let outlooks: [ActivityOutlook]
            let day: Int?
        }

        private let ranking: [RankedActivity]
        private let received = Mutex<[Request]>([])

        init(ranking: [RankedActivity]) {
            self.ranking = ranking
        }

        var requests: [Request] {
            received.withLock { $0 }
        }

        func rank(_ outlooks: [ActivityOutlook], onDay day: Int?) -> [RankedActivity] {
            received.withLock { $0.append(Request(outlooks: outlooks, day: day)) }
            return ranking
        }
    }

    private static let ranker = ActivityRanker(tieBreakOrder: [.surfing, .outdoorSightseeing, .indoorSightseeing, .skiing])
    private static let week = forecast([
        outlook(.skiing, scores: [nil, nil, nil]),
        outlook(.surfing, scores: [80, 40, nil]),
        outlook(.indoorSightseeing, scores: [50, 90, 55]),
        outlook(.outdoorSightseeing, scores: [70, 70, 70]),
    ])

    @Test("Summarizes the injected ranker's ranking of the forecast's outlooks for the requested day")
    func injectedRanker() {
        let surfing = Self.outlook(.surfing, scores: [90, 90])
        let skiing = Self.outlook(.skiing, scores: [10, 10])
        let ranking = [
            RankedActivity(rank: 1, outlook: skiing, score: 30),
            RankedActivity(rank: 2, outlook: surfing, score: 90),
        ]
        let ranker = RecordingRanker(ranking: ranking)
        let summarizer = RankingSummarizer(ranker: ranker, strongScoreThreshold: 60)
        let forecast = Self.forecast([surfing, skiing])

        #expect(summarizer.summary(of: forecast, onDay: 1) == RankingSummary(ranking: ranking, selectedDay: 1, hasStrongTopPick: false))
        #expect(summarizer.summary(of: forecast, onDay: nil) == RankingSummary(ranking: ranking, selectedDay: nil, hasStrongTopPick: false))
        #expect(ranker.requests == [.init(outlooks: [surfing, skiing], day: 1), .init(outlooks: [surfing, skiing], day: nil)])
    }

    @Test("Strength is judged on the score the ranker gives its top pick")
    func rankerScoreDecidesStrength() {
        let weak = Self.outlook(.skiing, scores: [10])
        let strong = Self.outlook(.surfing, scores: [90])
        let lifted = RankingSummarizer(
            ranker: RecordingRanker(ranking: [RankedActivity(rank: 1, outlook: weak, score: 75)]),
            strongScoreThreshold: 60
        )
        let unscored = RankingSummarizer(
            ranker: RecordingRanker(ranking: [RankedActivity(rank: 1, outlook: strong, score: nil)]),
            strongScoreThreshold: 60
        )

        #expect(lifted.summary(of: Self.forecast([weak]), onDay: nil).hasStrongTopPick)
        #expect(!unscored.summary(of: Self.forecast([strong]), onDay: nil).hasStrongTopPick)
    }

    @Test("The week's summary ranks by weekly score, with the best activity as the top pick and the rest as others")
    func weekSummary() {
        let summary = RankingSummarizer(ranker: Self.ranker, strongScoreThreshold: 60).summary(of: Self.week, onDay: nil)

        #expect(summary.ranking.map(\.activity) == [.outdoorSightseeing, .indoorSightseeing, .surfing, .skiing])
        #expect(summary.ranking.map(\.rank) == [1, 2, 3, 4])
        #expect(summary.ranking.map(\.score) == [70, 65, 40, nil])
        #expect(summary.topPick?.activity == .outdoorSightseeing)
        #expect(summary.others.map(\.activity) == [.indoorSightseeing, .surfing, .skiing])
        #expect(summary.topPickBestDayOfWeek == DayScore(day: 0, score: 70))
        #expect(summary.selectedDay == nil)
        #expect(summary.hasStrongTopPick)
    }

    @Test("A day's summary ranks by that day's score and keeps the selected day")
    func daySummary() {
        let summary = RankingSummarizer(ranker: Self.ranker, strongScoreThreshold: 60).summary(of: Self.week, onDay: 1)

        #expect(summary.ranking.map(\.activity) == [.indoorSightseeing, .outdoorSightseeing, .surfing, .skiing])
        #expect(summary.ranking.map(\.score) == [90, 70, 40, nil])
        #expect(summary.topPick?.activity == .indoorSightseeing)
        #expect(summary.others.map(\.activity) == [.outdoorSightseeing, .surfing, .skiing])
        #expect(summary.topPickBestDayOfWeek == DayScore(day: 1, score: 90))
        #expect(summary.selectedDay == 1)
        #expect(summary.hasStrongTopPick)
    }

    @Test("The top pick's best day is the best of its week, not the selected day")
    func topPickBestDayOfWeek() {
        let summarizer = RankingSummarizer(ranker: Self.ranker, strongScoreThreshold: 60)
        let summary = summarizer.summary(of: Self.week, onDay: 2)

        #expect(summary.ranking.map(\.activity) == [.outdoorSightseeing, .indoorSightseeing, .surfing, .skiing])
        #expect(summary.ranking.map(\.score) == [70, 55, nil, nil])
        #expect(summary.topPickBestDayOfWeek == DayScore(day: 0, score: 70))
        #expect(summary.selectedDay == 2)

        let forecast = Self.forecast([Self.outlook(.surfing, scores: [90, 50, 30]), Self.outlook(.skiing, scores: [nil, 40, nil])])
        let selected = summarizer.summary(of: forecast, onDay: 1)
        let week = summarizer.summary(of: forecast, onDay: nil)

        #expect(selected.topPick?.activity == .surfing)
        #expect(selected.topPick?.score == 50)
        #expect(selected.topPickBestDayOfWeek == DayScore(day: 0, score: 90))
        #expect(selected.topPickBestDayOfWeek == week.topPickBestDayOfWeek)
    }

    @Test("The top pick's best day is only offered when the top pick is suitable on the summarised day")
    func bestDayHintNeedsSuitableTopPick() {
        let summarizer = RankingSummarizer(ranker: Self.ranker, strongScoreThreshold: 60)
        let forecast = Self.forecast([Self.outlook(.surfing, scores: [90, nil]), Self.outlook(.skiing, scores: [nil, nil])])

        let unsuitableDay = summarizer.summary(of: forecast, onDay: 1)
        let suitableDay = summarizer.summary(of: forecast, onDay: 0)
        let week = summarizer.summary(of: forecast, onDay: nil)

        #expect(unsuitableDay.topPick?.activity == .surfing)
        #expect(unsuitableDay.topPick?.isSuitable == false)
        #expect(unsuitableDay.topPick?.outlook.bestDay == DayScore(day: 0, score: 90))
        #expect(unsuitableDay.topPickBestDayOfWeek == nil)
        #expect(suitableDay.topPickBestDayOfWeek == DayScore(day: 0, score: 90))
        #expect(week.topPick?.score == 45)
        #expect(week.topPickBestDayOfWeek == DayScore(day: 0, score: 90))
    }

    @Test("The best-day hint follows the score the ranker gives its top pick, not the top pick's week")
    func bestDayHintFollowsRankerScore() {
        let outlook = Self.outlook(.surfing, scores: [30, 80])
        let unscored = RankingSummarizer(
            ranker: RecordingRanker(ranking: [RankedActivity(rank: 1, outlook: outlook, score: nil)]),
            strongScoreThreshold: 60
        )
        let scored = RankingSummarizer(
            ranker: RecordingRanker(ranking: [RankedActivity(rank: 1, outlook: outlook, score: 0)]),
            strongScoreThreshold: 60
        )

        #expect(unscored.summary(of: Self.forecast([outlook]), onDay: 0).topPickBestDayOfWeek == nil)
        #expect(scored.summary(of: Self.forecast([outlook]), onDay: 0).topPickBestDayOfWeek == DayScore(day: 1, score: 80))
    }

    @Test("A top pick is strong from the threshold score upwards", arguments: zip([0, 59, 60, 61, 100], [false, false, true, true, true]))
    func thresholdBoundary(score: Int, isStrong: Bool) {
        let forecast = Self.forecast([Self.outlook(.skiing, scores: [0]), Self.outlook(.surfing, scores: [score])])
        let summary = RankingSummarizer(ranker: Self.ranker, strongScoreThreshold: 60).summary(of: forecast, onDay: nil)

        #expect(summary.topPick?.activity == .surfing)
        #expect(summary.topPick?.score == score)
        #expect(summary.hasStrongTopPick == isStrong)
    }

    @Test("The injected threshold decides what counts as a strong top pick")
    func customThreshold() {
        let forecast = Self.forecast([Self.outlook(.outdoorSightseeing, scores: [70])])
        let strength = [50, 69, 70, 71, 90].map { threshold in
            RankingSummarizer(ranker: Self.ranker, strongScoreThreshold: threshold).summary(of: forecast, onDay: nil).hasStrongTopPick
        }

        #expect(strength == [true, true, true, false, false])
    }

    @Test("Strength follows the top pick's score on the selected day, not its weekly score")
    func strengthPerDay() {
        let forecast = Self.forecast([Self.outlook(.surfing, scores: [90, 50]), Self.outlook(.skiing, scores: [nil, 40])])
        let summarizer = RankingSummarizer(ranker: Self.ranker, strongScoreThreshold: 60)
        let summaries = [nil, 0, 1].map { summarizer.summary(of: forecast, onDay: $0) }

        #expect(summaries.map { $0.topPick?.activity } == [.surfing, .surfing, .surfing])
        #expect(summaries.map { $0.topPick?.score } == [70, 90, 50])
        #expect(summaries.map(\.hasStrongTopPick) == [true, true, false])
    }

    @Test("A forecast where nothing is suitable has no strong top pick, even with a zero threshold")
    func allUnsuitable() {
        let forecast = Self.forecast(Activity.allCases.map { Self.outlook($0, scores: [nil, nil]) })
        let summarizer = RankingSummarizer(ranker: Self.ranker, strongScoreThreshold: 0)

        for day in [nil, 0, 1] {
            let summary = summarizer.summary(of: forecast, onDay: day)
            #expect(summary.ranking.map(\.activity) == [.surfing, .outdoorSightseeing, .indoorSightseeing, .skiing])
            #expect(summary.ranking.allSatisfy { !$0.isSuitable })
            #expect(summary.topPickBestDayOfWeek == nil)
            #expect(!summary.hasStrongTopPick)
        }
    }

    @Test("An empty forecast has no top pick, no others and no strong pick, but keeps the selected day")
    func emptyForecast() {
        let summarizer = RankingSummarizer(ranker: Self.ranker, strongScoreThreshold: 0)

        #expect(summarizer.summary(of: Self.forecast([]), onDay: nil) == RankingSummary(ranking: [], selectedDay: nil, hasStrongTopPick: false))
        let daySummary = summarizer.summary(of: Self.forecast([]), onDay: 3)
        #expect(daySummary == RankingSummary(ranking: [], selectedDay: 3, hasStrongTopPick: false))
        #expect(daySummary.topPick == nil)
        #expect(daySummary.others.isEmpty)
        #expect(daySummary.topPickBestDayOfWeek == nil)
    }

    private static func outlook(_ activity: Activity, scores: [Int?]) -> ActivityOutlook {
        let days = scores.map { score in
            score.map { DayAssessment(score: $0, effects: [:]) } ?? DayAssessment(blockedBy: .rain, effects: [:])
        }
        return ActivityOutlook(activity: activity, days: days, factors: [])
    }

    private static func forecast(_ outlooks: [ActivityOutlook]) -> CityForecast {
        CityForecast(
            city: Fixtures.lisbon,
            days: Fixtures.week(startingOn: Fixtures.referenceNow, in: "Europe/Lisbon", count: outlooks.map(\.days.count).max() ?? 0),
            outlooks: outlooks,
            fetchedAt: Fixtures.referenceNow
        )
    }
}
