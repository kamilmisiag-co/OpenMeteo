//
//  BlockingRuleTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic
import Testing

@Suite("Blocking rules")
struct BlockingRuleTests {
    private let noSnow = NoSnowBlocker(minimumDepthCm: 10, minimumSnowfallCm: 1)

    @Test("A condition blocker blocks exactly the days with one of its conditions, under its own kind")
    func conditionBlocker() {
        let blocker = ConditionBlocker(kind: .thunderstorm, conditions: [.thunderstorm, .rain])
        let days = [WeatherCondition.clear, .thunderstorm, .drizzle, .rain, .snow].map { Fixtures.day(condition: $0) }
        #expect(blockedDays(by: blocker, in: days) == [false, true, false, true, false])
        #expect(blocker.kind == .thunderstorm)
    }

    @Test("A condition blocker without conditions never blocks")
    func noConditions() {
        let days = WeatherCondition.allCases.map { Fixtures.day(condition: $0) }
        #expect(!blockedDays(by: ConditionBlocker(kind: .wind, conditions: []), in: days).contains(true))
    }

    @Test("Blockers never block a day outside the forecast")
    func outOfRange() {
        let blockers: [any BlockingRule] = [ConditionBlocker(kind: .thunderstorm, conditions: [.thunderstorm]), noSnow]
        let days = [Fixtures.day(condition: .thunderstorm, snowfall: 0, snowDepth: nil)]
        for blocker in blockers {
            #expect(blocker.blocks(day: 0, in: days))
            #expect(!blocker.blocks(day: 1, in: days))
            #expect(!blocker.blocks(day: -1, in: days))
            #expect(!blocker.blocks(day: 0, in: []))
        }
    }

    @Test("A lack of snow is reported as a snowfall blocker")
    func noSnowKind() {
        #expect(noSnow.kind == .snowfall)
    }

    @Test("A day with too little snow on the ground and too little falling is blocked")
    func tooLittleSnow() {
        #expect(noSnow.blocks(day: 0, in: [Fixtures.day(snowfall: 0, snowDepth: nil)]))
        #expect(noSnow.blocks(day: 0, in: [Fixtures.day(snowfall: 0.5, snowDepth: 5)]))
        #expect(noSnow.blocks(day: 0, in: [Fixtures.day(snowfall: 0, snowDepth: 9.9)]))
    }

    @Test("Enough snow on the ground opens the day")
    func enoughDepth() {
        #expect(!noSnow.blocks(day: 0, in: [Fixtures.day(snowfall: 0, snowDepth: 10)]))
        #expect(!noSnow.blocks(day: 0, in: [Fixtures.day(snowfall: 0, snowDepth: 30)]))
    }

    @Test("Enough fresh snow opens the day, even without a known snow depth")
    func enoughSnowfall() {
        #expect(!noSnow.blocks(day: 0, in: [Fixtures.day(snowfall: 1, snowDepth: nil)]))
        #expect(!noSnow.blocks(day: 0, in: [Fixtures.day(snowfall: 4, snowDepth: 2)]))
    }

    @Test("Snow that fell earlier in the window counts towards later days, but not the other way round")
    func cumulativeSnowfall() {
        let trickle = [0.5, 0, 0.5, 0, 0].map { Fixtures.day(snowfall: $0, snowDepth: nil) }
        #expect(blockedDays(by: noSnow, in: trickle) == [true, true, false, false, false])
        let lateDump = [0, 0, 3].map { Fixtures.day(snowfall: $0, snowDepth: nil) }
        #expect(blockedDays(by: noSnow, in: lateDump) == [true, true, false])
    }

    private func blockedDays(by blocker: any BlockingRule, in days: [DailyWeather]) -> [Bool] {
        days.indices.map { blocker.blocks(day: $0, in: days) }
    }
}
