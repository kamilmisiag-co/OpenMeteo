//
//  UpcomingDaysWindowTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Logic
import LogicMocks
import Testing
import Utils
import UtilsMocks

@Suite("Upcoming days window")
struct UpcomingDaysWindowTests {
    private static let lisbonTimeZone = TimeZone(identifier: "Europe/Lisbon")!
    private static let aucklandTimeZone = TimeZone(identifier: "Pacific/Auckland")!
    private static let aucklandCalendar = Calendar.gregorian(timeZone: aucklandTimeZone)
    private static let utcCalendar = Calendar.gregorian(timeZone: TimeZone(identifier: "UTC")!)
    private static let aucklandEarlyMorning = aucklandCalendar.date(year: 2026, month: 10, day: 18, hour: 1)
    private static let utcMidnights = LogicFixtures.days(count: 3, in: "UTC")
    private static let unknownZone = City(
        id: 2, name: "Atlantis", region: nil, country: "Atlantis", countryCode: nil,
        latitude: 0, longitude: 0, timeZoneIdentifier: "Atlantis/Lost_City"
    )

    private let window = UpcomingDaysWindow(dayCount: 7, fallbackTimeZone: Self.lisbonTimeZone)

    @Test("Days before today are dropped and today is kept even though it started before now")
    func dropsPastDays() {
        let days = LogicFixtures.days(from: 14, count: 7)
        #expect(window.upcomingDays(days, in: SampleCities.lisbon, now: LogicFixtures.referenceNow) == Array(days.dropFirst(3)))
    }

    @Test("A day stops being upcoming at the city's local midnight")
    func localMidnight() {
        let days = LogicFixtures.days(from: 17, count: 2)
        let lastMinute = Fixtures.lisbonCalendar.date(year: 2026, month: 10, day: 17, hour: 23, minute: 59)
        let midnight = Fixtures.lisbonCalendar.date(year: 2026, month: 10, day: 18)
        #expect(window.upcomingDays(days, in: SampleCities.lisbon, now: lastMinute) == days)
        #expect(window.upcomingDays(days, in: SampleCities.lisbon, now: midnight) == Array(days.dropFirst()))
    }

    @Test("The same instant is a different today in each city's time zone")
    func cityTimeZones() {
        let days = Self.utcMidnights
        #expect(window.upcomingDays(days, in: SampleCities.lisbon, now: Self.aucklandEarlyMorning) == days)
        #expect(window.upcomingDays(days, in: Fixtures.auckland, now: Self.aucklandEarlyMorning) == Array(days.dropFirst()))
    }

    @Test("A city without a usable time zone uses the injected fallback")
    func fallbackTimeZone() {
        let days = Self.utcMidnights
        let aucklandFallback = UpcomingDaysWindow(dayCount: 7, fallbackTimeZone: Self.aucklandTimeZone)
        let lisbonFallback = UpcomingDaysWindow(dayCount: 7, fallbackTimeZone: Self.lisbonTimeZone)
        #expect(aucklandFallback.upcomingDays(days, in: SampleCities.noTimeZone, now: Self.aucklandEarlyMorning) == Array(days.dropFirst()))
        #expect(lisbonFallback.upcomingDays(days, in: SampleCities.noTimeZone, now: Self.aucklandEarlyMorning) == days)
        #expect(aucklandFallback.upcomingDays(days, in: Self.unknownZone, now: Self.aucklandEarlyMorning) == Array(days.dropFirst()))
    }

    @Test("A city's own time zone wins over the fallback")
    func cityZoneWins() {
        let aucklandFallback = UpcomingDaysWindow(dayCount: 7, fallbackTimeZone: Self.aucklandTimeZone)
        #expect(aucklandFallback.upcomingDays(Self.utcMidnights, in: SampleCities.lisbon, now: Self.aucklandEarlyMorning) == Self.utcMidnights)
    }

    @Test("Unsorted days come back in date order")
    func sorting() {
        let days = LogicFixtures.days(from: 17, count: 5)
        #expect(window.upcomingDays(days.reversed(), in: SampleCities.lisbon, now: LogicFixtures.referenceNow) == days)
        #expect(window.upcomingDays([3, 0, 4, 1, 2].map { days[$0] }, in: SampleCities.lisbon, now: LogicFixtures.referenceNow) == days)
    }

    @Test("Only the earliest entry of each local day is kept")
    func duplicates() {
        let today = LogicFixtures.day(on: Fixtures.lisbonCalendar.date(year: 2026, month: 10, day: 17))
        let morning = LogicFixtures.day(on: Fixtures.lisbonCalendar.date(year: 2026, month: 10, day: 18), high: 18)
        let afternoon = LogicFixtures.day(on: Fixtures.lisbonCalendar.date(year: 2026, month: 10, day: 18, hour: 15), high: 26)
        let days = [today, afternoon, morning, morning, today]
        #expect(window.upcomingDays(days, in: SampleCities.lisbon, now: LogicFixtures.referenceNow) == [today, morning])
    }

    @Test("Duplicates are judged by the city's local calendar day")
    func localDuplicates() {
        let first = LogicFixtures.day(on: Self.utcCalendar.date(year: 2026, month: 10, day: 17, hour: 11))
        let second = LogicFixtures.day(on: Self.utcCalendar.date(year: 2026, month: 10, day: 18, hour: 10), high: 25)
        #expect(window.upcomingDays([second, first], in: Fixtures.auckland, now: Self.aucklandEarlyMorning) == [first])
        #expect(window.upcomingDays([second, first], in: SampleCities.lisbon, now: Self.aucklandEarlyMorning) == [first, second])
    }

    @Test("At most the configured number of days is returned, counted after dropping past days")
    func truncation() {
        let days = LogicFixtures.days(from: 14, count: 12)
        #expect(window.dayCount == 7)
        #expect(window.upcomingDays(days, in: SampleCities.lisbon, now: LogicFixtures.referenceNow) == Array(days.dropFirst(3).prefix(7)))
        let shortWindow = UpcomingDaysWindow(dayCount: 2, fallbackTimeZone: Self.lisbonTimeZone)
        #expect(shortWindow.dayCount == 2)
        #expect(shortWindow.upcomingDays(days, in: SampleCities.lisbon, now: LogicFixtures.referenceNow) == Array(days.dropFirst(3).prefix(2)))
    }

    @Test("Days on both sides of a daylight saving change stay separate")
    func daylightSaving() {
        let days = LogicFixtures.days(from: 23, count: 7)
        let beforeChange = Fixtures.lisbonCalendar.date(year: 2026, month: 10, day: 23, hour: 8)
        let afterChange = Fixtures.lisbonCalendar.date(year: 2026, month: 10, day: 26, hour: 8)
        #expect(window.upcomingDays(days, in: SampleCities.lisbon, now: beforeChange) == days)
        #expect(window.upcomingDays(days, in: SampleCities.lisbon, now: afterChange) == Array(days.dropFirst(3)))
    }

    @Test("No days in gives no days out")
    func empty() {
        #expect(window.upcomingDays([], in: SampleCities.lisbon, now: LogicFixtures.referenceNow).isEmpty)
    }
}
