//
//  ToggleDaySelectorTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic
import Testing

@Suite("Toggle day selector")
struct ToggleDaySelectorTests {
    private let selector = ToggleDaySelector()

    @Test("Choosing no day shows the whole week")
    func choosingNoDay() {
        #expect(selector.selection(afterChoosing: nil, current: nil, dayCount: 7) == nil)
        #expect(selector.selection(afterChoosing: nil, current: 3, dayCount: 7) == nil)
        #expect(selector.selection(afterChoosing: nil, current: 9, dayCount: 7) == nil)
        #expect(selector.selection(afterChoosing: nil, current: nil, dayCount: 0) == nil)
    }

    @Test("Choosing the selected day again goes back to the whole week", arguments: [0, 3, 6])
    func choosingSelectedDay(day: Int) {
        #expect(selector.selection(afterChoosing: day, current: day, dayCount: 7) == nil)
    }

    @Test("Choosing the selected day again goes back to the whole week even when it no longer fits the forecast", arguments: [-1, 7, 9])
    func choosingSelectedDayOutOfRange(day: Int) {
        #expect(selector.selection(afterChoosing: day, current: day, dayCount: 7) == nil)
    }

    @Test("Every day within the forecast can be chosen", arguments: 0..<7)
    func choosingEachDay(day: Int) {
        #expect(selector.selection(afterChoosing: day, current: nil, dayCount: 7) == day)
        #expect(selector.selection(afterChoosing: day, current: (day + 1) % 7, dayCount: 7) == day)
    }

    @Test("Choosing a day within the forecast selects it")
    func choosingDayInRange() {
        #expect(selector.selection(afterChoosing: 4, current: nil, dayCount: 7) == 4)
        #expect(selector.selection(afterChoosing: 0, current: 6, dayCount: 7) == 0)
        #expect(selector.selection(afterChoosing: 6, current: 2, dayCount: 7) == 6)
        #expect(selector.selection(afterChoosing: 2, current: 9, dayCount: 3) == 2)
        #expect(selector.selection(afterChoosing: 0, current: nil, dayCount: 1) == 0)
    }

    @Test("The last day of the forecast can be chosen and the day after it cannot")
    func lastDayBoundary() {
        #expect(selector.selection(afterChoosing: 2, current: nil, dayCount: 3) == 2)
        #expect(selector.selection(afterChoosing: 3, current: nil, dayCount: 3) == nil)
        #expect(selector.selection(afterChoosing: 3, current: 2, dayCount: 3) == 2)
        #expect(selector.selection(afterChoosing: 2, current: 3, dayCount: 3) == 2)
    }

    @Test("Choosing a day outside the forecast keeps a selection that is still valid", arguments: [-1, 7, 8, Int.max, Int.min])
    func choosingDayOutOfRangeKeepsSelection(day: Int) {
        #expect(selector.selection(afterChoosing: day, current: 2, dayCount: 7) == 2)
        #expect(selector.selection(afterChoosing: day, current: 0, dayCount: 7) == 0)
        #expect(selector.selection(afterChoosing: day, current: 6, dayCount: 7) == 6)
    }

    @Test("Choosing a day outside the forecast without a valid selection shows the whole week", arguments: [-1, 7, 8, Int.max, Int.min])
    func choosingDayOutOfRangeWithoutSelection(day: Int) {
        #expect(selector.selection(afterChoosing: day, current: nil, dayCount: 7) == nil)
        #expect(selector.selection(afterChoosing: day, current: 7, dayCount: 7) == nil)
        #expect(selector.selection(afterChoosing: day, current: -2, dayCount: 7) == nil)
        #expect(selector.selection(afterChoosing: day, current: Int.max, dayCount: 7) == nil)
    }

    @Test("No day can be selected in an empty forecast", arguments: [0, -3])
    func emptyForecast(dayCount: Int) {
        #expect(selector.selection(afterChoosing: 0, current: nil, dayCount: dayCount) == nil)
        #expect(selector.selection(afterChoosing: 1, current: 0, dayCount: dayCount) == nil)
        #expect(selector.selection(afterChoosing: 0, current: 2, dayCount: dayCount) == nil)
        #expect(selector.selection(afterChoosing: -1, current: nil, dayCount: dayCount) == nil)
        #expect(selector.selection(afterChoosing: 2, current: -1, dayCount: dayCount) == nil)
    }
}
