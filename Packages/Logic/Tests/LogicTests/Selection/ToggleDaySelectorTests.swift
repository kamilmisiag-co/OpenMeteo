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

    @Test("Choosing the selected day again goes back to the whole week")
    func choosingSelectedDay() {
        #expect(selector.selection(afterChoosing: 3, current: 3, dayCount: 7) == nil)
    }

    @Test("Choosing the selected day again goes back to the whole week even when it no longer fits the forecast")
    func choosingSelectedDayOutOfRange() {
        #expect(selector.selection(afterChoosing: 7, current: 7, dayCount: 7) == nil)
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

    @Test("Choosing a day outside the forecast keeps a selection that is still valid", arguments: [-1, 7])
    func choosingDayOutOfRangeKeepsSelection(day: Int) {
        #expect(selector.selection(afterChoosing: day, current: 2, dayCount: 7) == 2)
        #expect(selector.selection(afterChoosing: day, current: 0, dayCount: 7) == 0)
        #expect(selector.selection(afterChoosing: day, current: 6, dayCount: 7) == 6)
    }

    @Test("Choosing a day outside the forecast without a valid selection shows the whole week", arguments: [-1, 7])
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
