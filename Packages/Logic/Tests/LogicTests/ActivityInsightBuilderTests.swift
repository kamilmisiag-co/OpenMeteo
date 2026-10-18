//
//  ActivityInsightBuilderTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic
import Synchronization
import Testing

@Suite("Activity insight builder")
struct ActivityInsightBuilderTests {
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

    private static let surfing = outlook(.surfing, days: [scored(80), blocked(.wind), blocked(.wind), scored(60)])
    private static let outdoor = outlook(.outdoorSightseeing, days: [scored(70), scored(70), scored(80), blocked(.rain)])
    private static let indoor = outlook(.indoorSightseeing, days: [scored(60), scored(60), scored(60), scored(60)])
    private static let skiing = outlook(.skiing, days: [blocked(.temperature), blocked(.snowfall), blocked(.temperature), blocked(.snowfall)])
    private static let week = forecast([surfing, skiing, outdoor, indoor])
    private let builder = ActivityInsightBuilder(
        ranker: ActivityRanker(tieBreakOrder: [.surfing, .outdoorSightseeing, .indoorSightseeing, .skiing])
    )

    @Test("Ranks the forecast's week with the injected ranker and takes the rank from its order")
    func injectedRanker() {
        let ranker = RecordingRanker(ranking: [
            RankedActivity(rank: 1, outlook: Self.skiing, score: nil),
            RankedActivity(rank: 2, outlook: Self.surfing, score: 35),
            RankedActivity(rank: 3, outlook: Self.indoor, score: 60),
        ])
        let builder = ActivityInsightBuilder(ranker: ranker)
        let forecast = Self.forecast([Self.surfing, Self.skiing, Self.indoor])

        let skiing = ActivityInsight(outlook: Self.skiing, rank: 1, rankedCount: 3, dominantBlocker: .temperature)
        let indoor = ActivityInsight(outlook: Self.indoor, rank: 3, rankedCount: 3, dominantBlocker: nil)
        #expect(builder.insight(for: .skiing, in: forecast) == skiing)
        #expect(builder.insight(for: .indoorSightseeing, in: forecast) == indoor)
        #expect(ranker.requests == [.init(outlooks: forecast.outlooks, day: nil), .init(outlooks: forecast.outlooks, day: nil)])
    }

    @Test("The insight describes the outlook from the ranker's entry")
    func outlookFromRanking() {
        let ranked = Self.outlook(.surfing, days: [Self.blocked(.thunderstorm), Self.scored(50)])
        let builder = ActivityInsightBuilder(ranker: RecordingRanker(ranking: [RankedActivity(rank: 1, outlook: ranked, score: 25)]))

        let insight = builder.insight(for: .surfing, in: Self.forecast([Self.surfing]))
        #expect(insight == ActivityInsight(outlook: ranked, rank: 1, rankedCount: 1, dominantBlocker: .thunderstorm))
    }

    @Test("An activity the ranker leaves out has no insight")
    func missingFromRanking() {
        let builder = ActivityInsightBuilder(ranker: RecordingRanker(ranking: [RankedActivity(rank: 1, outlook: Self.indoor, score: 60)]))

        #expect(builder.insight(for: .surfing, in: Self.forecast([Self.surfing, Self.indoor])) == nil)
    }

    @Test("Places each activity at its position among all the forecast's activities")
    func rankOfCount() {
        let activities: [Activity] = [.indoorSightseeing, .outdoorSightseeing, .surfing, .skiing]
        let insights = activities.map { builder.insight(for: $0, in: Self.week) }

        #expect(insights.map { $0?.activity } == activities)
        #expect(insights.map { $0?.rank } == [1, 2, 3, 4])
        #expect(insights.map { $0?.rankedCount } == [4, 4, 4, 4])
    }

    @Test("Ranks over the whole week rather than a single day")
    func weekRanking() throws {
        let surfing = try #require(builder.insight(for: .surfing, in: Self.week))

        #expect(Self.surfing.score(onDay: 0) == 80)
        #expect(surfing.rank == 3)
        #expect(surfing.weeklyScore == 35)
    }

    @Test("Reports the activity's weekly score and best day from its outlook")
    func outlookPassthrough() throws {
        let outdoor = try #require(builder.insight(for: .outdoorSightseeing, in: Self.week))
        let skiing = try #require(builder.insight(for: .skiing, in: Self.week))

        #expect(outdoor == ActivityInsight(outlook: Self.outdoor, rank: 2, rankedCount: 4, dominantBlocker: .rain))
        #expect(outdoor.weeklyScore == 55)
        #expect(outdoor.bestDay == DayScore(day: 2, score: 80))
        #expect(skiing.outlook == Self.skiing)
        #expect(skiing.weeklyScore == nil)
        #expect(skiing.bestDay == nil)
    }

    @Test("The blocker that blocks the most days is dominant")
    func mostFrequentBlocker() {
        let rainy = Self.outlook(.surfing, days: [
            Self.blocked(.rain), Self.blocked(.wind), Self.blocked(.rain), Self.scored(50), Self.blocked(.thunderstorm),
        ])

        #expect(builder.insight(for: .surfing, in: Self.forecast([rainy]))?.dominantBlocker == .rain)
        #expect(builder.insight(for: .surfing, in: Self.week)?.dominantBlocker == .wind)
    }

    @Test("Blockers that block equally often are settled by factor order, not by which comes first")
    func blockerTieBreak() {
        let stormy = Self.outlook(.surfing, days: [
            Self.blocked(.snowfall), Self.blocked(.thunderstorm), Self.blocked(.thunderstorm), Self.blocked(.snowfall),
        ])

        #expect(builder.insight(for: .surfing, in: Self.forecast([stormy]))?.dominantBlocker == .thunderstorm)
        #expect(builder.insight(for: .skiing, in: Self.week)?.dominantBlocker == .temperature)
    }

    @Test("Factors that only hurt scored days are not blockers")
    func hurtingFactorsAreNotBlockers() {
        let windy = Self.outlook(.surfing, days: [
            DayAssessment(score: 40, effects: [.wind: .hurts]), DayAssessment(score: 30, effects: [.wind: .hurts, .rain: .hurts]), Self.blocked(.temperature),
        ])
        let unblocked = Self.outlook(.surfing, days: [DayAssessment(score: 40, effects: [.wind: .hurts]), DayAssessment(score: 30, effects: [.rain: .hurts])])

        #expect(builder.insight(for: .surfing, in: Self.forecast([windy]))?.dominantBlocker == .temperature)
        #expect(builder.insight(for: .surfing, in: Self.forecast([unblocked]))?.dominantBlocker == nil)
        #expect(builder.insight(for: .indoorSightseeing, in: Self.week)?.dominantBlocker == nil)
    }

    @Test("An activity missing from the forecast has no insight")
    func missingActivity() {
        let forecast = Self.forecast([Self.surfing, Self.indoor])

        #expect(builder.insight(for: .skiing, in: forecast) == nil)
        #expect(builder.insight(for: .outdoorSightseeing, in: forecast) == nil)
        #expect(Activity.allCases.allSatisfy { builder.insight(for: $0, in: Self.forecast([])) == nil })
    }

    private static func scored(_ score: Int) -> DayAssessment {
        DayAssessment(score: score, effects: [:])
    }

    private static func blocked(_ kind: Factor.Kind) -> DayAssessment {
        DayAssessment(blockedBy: kind, effects: [:])
    }

    private static func outlook(_ activity: Activity, days: [DayAssessment]) -> ActivityOutlook {
        ActivityOutlook(activity: activity, days: days, factors: [])
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
