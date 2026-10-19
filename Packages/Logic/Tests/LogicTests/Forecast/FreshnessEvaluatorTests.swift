//
//  FreshnessEvaluatorTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Logic
import LogicMocks
import Testing

@Suite("Freshness evaluator")
struct FreshnessEvaluatorTests {
    private static let threeHours: TimeInterval = 3 * 60 * 60

    private let evaluator = FreshnessEvaluator(staleAfter: .seconds(3 * 60 * 60))
    private let fetchedAt = LogicFixtures.referenceNow

    @Test("A live forecast stays fresh up to and including the stale threshold")
    func fresh() {
        let live = LogicFixtures.result(origin: .live)
        #expect(evaluator.freshness(of: live, at: fetchedAt) == .fresh)
        #expect(evaluator.freshness(of: live, at: fetchedAt.addingTimeInterval(1)) == .fresh)
        #expect(evaluator.freshness(of: live, at: fetchedAt.addingTimeInterval(Self.threeHours)) == .fresh)
    }

    @Test("A live forecast older than the threshold is stale since it was fetched")
    func stale() {
        let live = LogicFixtures.result(origin: .live)
        #expect(evaluator.freshness(of: live, at: fetchedAt.addingTimeInterval(Self.threeHours + 1)) == .stale(since: fetchedAt))
        #expect(evaluator.freshness(of: live, at: fetchedAt.addingTimeInterval(7 * 24 * 60 * 60)) == .stale(since: fetchedAt))
    }

    @Test("A live forecast fetched after now counts as fresh")
    func fetchedInTheFuture() {
        let live = LogicFixtures.result(origin: .live)
        #expect(evaluator.freshness(of: live, at: fetchedAt.addingTimeInterval(-60)) == .fresh)
        #expect(evaluator.freshness(of: live, at: .distantPast) == .fresh)
    }

    @Test("A cached forecast is offline since it was fetched, even past the stale threshold")
    func offline() {
        let cached = LogicFixtures.result(origin: .cache)
        #expect(evaluator.freshness(of: cached, at: fetchedAt.addingTimeInterval(Self.threeHours + 1)) == .offline(since: fetchedAt))
    }

    @Test("The stale threshold is configurable down to fractions of a second")
    func configurableThreshold() {
        let live = LogicFixtures.result(origin: .live)
        let immediate = FreshnessEvaluator(staleAfter: .zero)
        #expect(immediate.freshness(of: live, at: fetchedAt) == .fresh)
        #expect(immediate.freshness(of: live, at: fetchedAt.addingTimeInterval(0.5)) == .stale(since: fetchedAt))
        let short = FreshnessEvaluator(staleAfter: .milliseconds(1500))
        #expect(short.freshness(of: live, at: fetchedAt.addingTimeInterval(1.5)) == .fresh)
        #expect(short.freshness(of: live, at: fetchedAt.addingTimeInterval(1.75)) == .stale(since: fetchedAt))
    }
}
