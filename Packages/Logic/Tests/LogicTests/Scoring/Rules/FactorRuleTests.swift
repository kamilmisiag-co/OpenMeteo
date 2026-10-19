//
//  FactorRuleTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic
import LogicMocks
import Testing

@Suite("Factor rules")
struct FactorRuleTests {
    private struct ScaledCurve: SuitabilityCurve {
        let divisor: Double

        func suitability(of value: Double) -> Double {
            value / divisor
        }
    }

    private struct ConstantCurve: SuitabilityCurve {
        let rating: Double

        func suitability(of value: Double) -> Double {
            rating
        }
    }

    @Test("Every rule has no rating for a day outside the forecast")
    func outOfRange() {
        let days = [LogicFixtures.day()]
        for rule in everyRule(using: ConstantCurve(rating: 1)) {
            #expect(rule.suitability(ofDay: 0, in: days) == 1)
            #expect(rule.suitability(ofDay: 1, in: days) == nil)
            #expect(rule.suitability(ofDay: -1, in: days) == nil)
            #expect(rule.suitability(ofDay: 0, in: []) == nil)
        }
    }

    @Test("The temperature rule rates each day's high")
    func temperature() {
        let rule = TemperatureRule(weight: 1, highCurve: ScaledCurve(divisor: 100))
        let days = [LogicFixtures.day(high: 45, low: 30), LogicFixtures.day(high: 12, low: 3)]
        #expect(ratings(by: rule, of: days) == [0.45, 0.12])
    }

    @Test("The snowfall rule rates each day's fresh snow")
    func snowfall() {
        let rule = SnowfallRule(weight: 1, snowfallCurve: ScaledCurve(divisor: 100))
        let days = [LogicFixtures.day(snowfall: 25, snowDepth: 80), LogicFixtures.day(snowfall: 0, snowDepth: 80)]
        #expect(ratings(by: rule, of: days) == [0.25, 0])
    }

    @Test("The wind rule rates the worse of the wind speed and the gusts")
    func wind() {
        let day = [LogicFixtures.day(wind: 30, gusts: 80)]
        let speedOnly = WindRule(weight: 1, speedCurve: ScaledCurve(divisor: 100), gustCurve: ConstantCurve(rating: 1))
        let gustsOnly = WindRule(weight: 1, speedCurve: ConstantCurve(rating: 1), gustCurve: ScaledCurve(divisor: 100))
        #expect(speedOnly.suitability(ofDay: 0, in: day) == 0.3)
        #expect(gustsOnly.suitability(ofDay: 0, in: day) == 0.8)
        let ramps = WindRule(
            weight: 1,
            speedCurve: DescendingRamp(fullUntil: 20, zeroFrom: 50),
            gustCurve: DescendingRamp(fullUntil: 35, zeroFrom: 75)
        )
        #expect(ratings(by: ramps, of: [LogicFixtures.day(wind: 32, gusts: 55), LogicFixtures.day(wind: 35, gusts: 40)]) == [0.5, 0.5])
    }

    @Test("The rain rule rates the precipitation probability after clamping it to 0...1")
    func rain() {
        let rule = RainRule(weight: 1, probabilityCurve: ScaledCurve(divisor: 2), minimumHighCelsius: nil)
        let days = [LogicFixtures.day(rain: 0.6), LogicFixtures.day(rain: 1.4), LogicFixtures.day(rain: -0.2)]
        #expect(ratings(by: rule, of: days) == [0.3, 0.5, 0])
    }

    @Test("The rain rule has no rating without a precipitation probability, even on a freezing day")
    func unknownRain() {
        let rule = RainRule(weight: 1, probabilityCurve: ConstantCurve(rating: 1), minimumHighCelsius: 1)
        #expect(ratings(by: rule, of: [LogicFixtures.day(high: 20, rain: nil), LogicFixtures.day(high: -5, low: -9, rain: nil)]) == [nil, nil])
    }

    @Test("Precipitation on a day no warmer than the minimum high falls as snow, so rain can't count against it")
    func rainAsSnow() {
        let rule = RainRule(weight: 1, probabilityCurve: ConstantCurve(rating: 0.2), minimumHighCelsius: 1)
        let days = [
            LogicFixtures.day(high: 1, low: -3, rain: 0.9),
            LogicFixtures.day(high: -6, low: -12, rain: 0.9),
            LogicFixtures.day(high: 1.5, low: -2, rain: 0.9),
        ]
        #expect(ratings(by: rule, of: days) == [1, 1, 0.2])
        let alwaysRain = RainRule(weight: 1, probabilityCurve: ConstantCurve(rating: 0.2), minimumHighCelsius: nil)
        #expect(alwaysRain.suitability(ofDay: 0, in: [LogicFixtures.day(high: -10, low: -15, rain: 0.9)]) == 0.2)
    }

    private func everyRule(using curve: any SuitabilityCurve) -> [any FactorRule] {
        [
            RainRule(weight: 0.2, probabilityCurve: curve, minimumHighCelsius: nil),
            WindRule(weight: 0.45, speedCurve: curve, gustCurve: curve),
            TemperatureRule(weight: 0.3, highCurve: curve),
            SnowfallRule(weight: 0.25, snowfallCurve: curve),
        ]
    }

    private func ratings(by rule: any FactorRule, of days: [DailyWeather]) -> [Double?] {
        days.indices.map { rule.suitability(ofDay: $0, in: days) }
    }
}
