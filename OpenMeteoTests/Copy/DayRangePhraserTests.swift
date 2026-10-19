//
//  DayRangePhraserTests.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic
import Testing
@testable import OpenMeteo

@Suite("Day range phrases")
@MainActor
struct DayRangePhraserTests {
    private let phraser = DayRangePhraser()
    private let days = Fixtures.days(Fixtures.lisbonWeather)
    private let format = LabelledForecastFormat(timeZone: Fixtures.lisbonTimeZone)

    private func phrase(_ indices: [Int], dayCount: Int = 7) -> String? {
        phraser.phrase(forDays: indices, in: Array(days.prefix(dayCount)), format: format)
    }

    private func weekday(_ index: Int) -> String {
        format.weekday(days[index].date)
    }

    private func range(_ first: Int, _ last: Int) -> String {
        String(localized: .dayRange(weekday(first), weekday(last)))
    }

    @Test("A single day reads as its weekday")
    func singleDay() {
        #expect(phrase([5]) == weekday(5))
    }

    @Test("Consecutive days read as a range from the first weekday to the last")
    func run() {
        #expect(phrase(Array(2...5)) == range(2, 5))
    }

    @Test("Separate runs are joined by the format's list")
    func severalRuns() {
        #expect(phrase([0, 1, 3, 5, 6]) == format.list([range(0, 1), weekday(3), range(5, 6)]))
    }

    @Test("Indices are sorted, de-duplicated and kept inside the forecast")
    func normalisedIndices() {
        #expect(phrase([4, 0, 2, 1, 1, 9, -1]) == format.list([range(0, 2), weekday(4)]))
    }

    @Test("Every day of the forecast reads as all week", arguments: [
        (Array(0...4), 5),
        ([6, 5, 4, 3, 2, 1, 0, 0, 7], 7),
    ])
    func allWeek(indices: [Int], dayCount: Int) {
        #expect(phrase(indices, dayCount: dayCount) == String(localized: .dayAllWeek))
    }

    @Test("No day inside the forecast gives no phrase", arguments: [
        ([7, -1], 7),
        ([0, 1], 0),
    ])
    func noDays(indices: [Int], dayCount: Int) {
        #expect(phrase(indices, dayCount: dayCount) == nil)
    }
}
