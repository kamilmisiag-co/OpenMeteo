//
//  FactorSummaryWriterTests.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic
import Testing
@testable import OpenMeteo

@Suite("Factor summaries")
@MainActor
struct FactorSummaryWriterTests {
    private let dayRanges = LabelledDayRanges()
    private let format = LabelledForecastFormat(timeZone: Fixtures.lisbonTimeZone)
    private let days = Fixtures.days(zip(Fixtures.lisbonWeather, [6.0, 6, 1, 0, 0, 0, 0]).map { day, snowfall in
        (condition: day.condition, high: day.high, low: day.low, rain: day.rain, wind: day.wind, gusts: day.gusts, snowfall: snowfall)
    })
    private let dryDays = Fixtures.days(Fixtures.lisbonWeather.map { day in
        (condition: day.condition, high: day.high, low: day.low, rain: Double?.none, wind: day.wind, gusts: day.gusts, snowfall: day.snowfall)
    })

    private var writer: FactorSummaryWriter {
        FactorSummaryWriter(dayRanges: dayRanges)
    }

    private var noValue: String {
        format.noValue
    }

    private var allWeek: String {
        String(localized: .dayAllWeek)
    }

    private func summary(_ factor: Factor, in assessments: [DayAssessment] = [], days: [DailyWeather]? = nil) -> String {
        let outlook = ActivityOutlook(activity: .skiing, days: assessments, factors: [factor])
        return writer.summary(of: factor, in: outlook, days: days ?? self.days, format: format)
    }

    private func label(_ indices: [Int]) -> String {
        LabelledDayRanges.label(indices, format: format)
    }

    @Test("Wind gives the strongest wind and gusts on the factor's days only")
    func wind() {
        let result = summary(Factor(kind: .wind, effect: .helps, days: [4, 0, 1, 2, 3]))

        #expect(result == String(localized: .factorWindSummary(format.speed(18), format.speed(30), label([0, 1, 2, 3, 4]))))
        #expect(dayRanges.requests == [LabelledDayRanges.Request(indices: [0, 1, 2, 3, 4], days: days)])
    }

    @Test("Rain gives the range of chances on the factor's days")
    func rain() {
        let result = summary(Factor(kind: .rain, effect: .hurts, days: [5, 6]))
        #expect(result == String(localized: .factorRainSummary(format.percentRange(0.5, 0.8), label([5, 6]))))
    }

    @Test("Rain without any chance on the factor's days has a missing value")
    func rainWithoutChances() {
        let result = summary(Factor(kind: .rain, effect: .hurts, days: [5]), days: dryDays)
        #expect(result == String(localized: .factorRainSummary(noValue, label([5]))))
    }

    @Test("Temperature gives the range of highs on the factor's days")
    func temperature() {
        let result = summary(Factor(kind: .temperature, effect: .hurts, days: [0, 1, 2, 3, 4]))
        #expect(result == String(localized: .factorTemperatureSummary(format.temperatureRange(22, 24), label([0, 1, 2, 3, 4]))))
    }

    @Test("Snowfall says there is not enough snow when every factor day is blocked by it")
    func snowfallBlocked() {
        let blocked = DayAssessment(blockedBy: .snowfall, effects: [:])
        let result = summary(Factor(kind: .snowfall, effect: .hurts, days: [0, 1]), in: [blocked, blocked])
        #expect(result == String(localized: .factorSnowfallSummaryBlocked(label([0, 1]))))
    }

    @Test("Snowfall totals the snow on the factor's days when any of them is not blocked by it", arguments: [
        [DayAssessment(blockedBy: .snowfall, effects: [:]), DayAssessment(score: 70, effects: [:])],
        [DayAssessment(blockedBy: .snowfall, effects: [:])],
    ])
    func snowfallTotal(assessments: [DayAssessment]) {
        let result = summary(Factor(kind: .snowfall, effect: .helps, days: [0, 1]), in: assessments)
        #expect(result == String(localized: .factorSnowfallSummary(format.snowfall(12), label([0, 1]))))
    }

    @Test("Thunderstorms name only the days")
    func thunderstorm() {
        let result = summary(Factor(kind: .thunderstorm, effect: .hurts, days: [5]))
        #expect(result == String(localized: .factorThunderstormSummary(label([5]))))
    }

    @Test("A factor without days inside the forecast is measured and phrased across the whole forecast")
    func daysOutsideForecast() {
        let result = summary(Factor(kind: .wind, effect: .hurts, days: [9, -1]))

        #expect(result == String(localized: .factorWindSummary(format.speed(32), format.speed(55), label(Array(0...6)))))
        #expect(dayRanges.requestedIndices == [Array(0...6)])
    }

    @Test("Without days every summary reads all week with missing values, and snowfall is never blocked")
    func emptyForecast() {
        let blocked = Array(repeating: DayAssessment(blockedBy: .snowfall, effects: [:]), count: 7)
        #expect(summary(Factor(kind: .wind, effect: .hurts, days: [0]), days: []) == String(localized: .factorWindSummary(noValue, noValue, allWeek)))
        #expect(summary(Factor(kind: .rain, effect: .hurts, days: [0]), days: []) == String(localized: .factorRainSummary(noValue, allWeek)))
        #expect(summary(Factor(kind: .temperature, effect: .hurts, days: [0]), days: []) == String(localized: .factorTemperatureSummary(noValue, allWeek)))
        #expect(
            summary(Factor(kind: .snowfall, effect: .hurts, days: [0]), in: blocked, days: [])
                == String(localized: .factorSnowfallSummary(format.snowfall(0), allWeek))
        )
        #expect(summary(Factor(kind: .thunderstorm, effect: .hurts, days: [0]), days: []) == String(localized: .factorThunderstormSummary(allWeek)))
    }

    @Test("Values span the whole forecast", arguments: [
        (Factor.Kind.wind, "10 kmh..32 kmh"),
        (Factor.Kind.rain, "0%..80%"),
        (Factor.Kind.temperature, "15°..24°"),
        (Factor.Kind.snowfall, "13 cm"),
    ])
    func value(kind: Factor.Kind, expected: String) {
        #expect(writer.value(of: kind, across: days, format: format) == expected)
    }

    @Test("Thunderstorms, and rain without any chance, have no value")
    func noValueKinds() {
        #expect(writer.value(of: .thunderstorm, across: days, format: format) == nil)
        #expect(writer.value(of: .rain, across: dryDays, format: format) == nil)
    }

    @Test("An empty forecast has no value", arguments: Factor.Kind.allCases)
    func emptyForecastValue(kind: Factor.Kind) {
        #expect(writer.value(of: kind, across: [], format: format) == nil)
    }
}
