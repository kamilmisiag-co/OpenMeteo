//
//  DateMatchingDaySelectionTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic
import LogicMocks
import Testing

@Suite("Date matching day selection")
struct DateMatchingDaySelectionTests {
    private static let week = LogicFixtures.days()
    private static let nextWeek = LogicFixtures.days(from: 18, count: 7)
    private static let shortWeek = LogicFixtures.days(from: 17, count: 4)
    private let selection = DateMatchingDaySelection()

    @Test("No selected day stays no selected day")
    func noSelectedDay() {
        #expect(selection.selection(nil, carriedFrom: Self.week, to: Self.week) == nil)
        #expect(selection.selection(nil, carriedFrom: Self.week, to: Self.nextWeek) == nil)
        #expect(selection.selection(nil, carriedFrom: [], to: Self.week) == nil)
    }

    @Test("When the week rolls forward by a day the same date stays selected at its new position")
    func weekRollsForward() {
        #expect(selection.selection(2, carriedFrom: Self.week, to: Self.nextWeek) == 1)
        #expect(selection.selection(1, carriedFrom: Self.week, to: Self.nextWeek) == 0)
        #expect(selection.selection(6, carriedFrom: Self.week, to: Self.nextWeek) == 5)
        #expect(Self.nextWeek[1].date == Self.week[2].date)
    }

    @Test("When the week moves back by a day the same date stays selected at its new position")
    func weekMovesBack() {
        #expect(selection.selection(1, carriedFrom: Self.nextWeek, to: Self.week) == 2)
        #expect(selection.selection(5, carriedFrom: Self.nextWeek, to: Self.week) == 6)
    }

    @Test("A refresh of the same days keeps the selected day")
    func sameWindow() {
        #expect(selection.selection(6, carriedFrom: Self.week, to: Self.week) == 6)
    }

    @Test("Days are matched by date alone, whatever the weather on them")
    func matchedByDate() {
        let rainy = Self.week.map { LogicFixtures.day(on: $0.date, condition: .rain, high: 9, low: 4, rain: 90) }
        #expect(selection.selection(3, carriedFrom: Self.week, to: rainy) == 3)
    }

    @Test("A selected date that is no longer in the forecast is dropped")
    func selectedDateDropped() {
        #expect(selection.selection(0, carriedFrom: Self.week, to: Self.nextWeek) == nil)
        #expect(selection.selection(6, carriedFrom: Self.nextWeek, to: Self.week) == nil)
        #expect(selection.selection(4, carriedFrom: Self.week, to: Self.shortWeek) == nil)
        #expect(selection.selection(6, carriedFrom: Self.week, to: Self.shortWeek) == nil)
        #expect(selection.selection(2, carriedFrom: Self.week, to: []) == nil)
    }

    @Test("A shorter forecast keeps a selected date it still contains")
    func shorterForecastKeepsDate() {
        #expect(selection.selection(3, carriedFrom: Self.week, to: Self.shortWeek) == 3)
        #expect(selection.selection(0, carriedFrom: Self.week, to: Self.shortWeek) == 0)
    }

    @Test("A selected day that was not in the previous days is dropped, even when the new days are long enough", arguments: [-1, 4])
    func invalidInPreviousDays(day: Int) {
        #expect(selection.selection(day, carriedFrom: Self.shortWeek, to: Self.week) == nil)
    }

    @Test("Empty previous days drop the selected day, whatever the new days")
    func emptyPreviousDays() {
        #expect(selection.selection(0, carriedFrom: [], to: Self.week) == nil)
        #expect(selection.selection(0, carriedFrom: [], to: []) == nil)
    }
}
