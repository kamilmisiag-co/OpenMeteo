//
//  UpcomingDaysWindowTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Logic
import Testing

@Suite("Upcoming days window")
struct UpcomingDaysWindowTests {
    private static let lisbonTimeZone = TimeZone(identifier: "Europe/Lisbon") ?? .gmt
    private static let aucklandTimeZone = TimeZone(identifier: "Pacific/Auckland") ?? .gmt
    private static let aucklandEarlyMorning = Fixtures.date(2026, 10, 18, hour: 1, in: "Pacific/Auckland")
    private static let utcMidnights = Fixtures.week(startingOn: Fixtures.date(2026, 10, 17, in: "UTC"), in: "UTC", count: 3)
    private static let unknownZone = City(
        id: 2, name: "Atlantis", region: nil, country: "Atlantis", countryCode: nil,
        latitude: 0, longitude: 0, timeZoneIdentifier: "Atlantis/Lost_City"
    )

    private let window = UpcomingDaysWindow(dayCount: 7, fallbackTimeZone: Self.lisbonTimeZone)

    @Test("Days before today are dropped and today is kept even though it started before now")
    func dropsPastDays() {
        let days = Fixtures.lisbonDays(from: 14, count: 7)
        #expect(window.upcomingDays(days, in: Fixtures.lisbon, now: Fixtures.referenceNow) == Array(days.dropFirst(3)))
    }

    @Test("A day stops being upcoming at the city's local midnight")
    func localMidnight() {
        let days = Fixtures.lisbonDays(from: 17, count: 2)
        let lastMinute = Fixtures.date(2026, 10, 17, hour: 23, minute: 59, in: "Europe/Lisbon")
        let midnight = Fixtures.date(2026, 10, 18, in: "Europe/Lisbon")
        #expect(window.upcomingDays(days, in: Fixtures.lisbon, now: lastMinute) == days)
        #expect(window.upcomingDays(days, in: Fixtures.lisbon, now: midnight) == Array(days.dropFirst()))
    }

    @Test("The same instant is a different today in each city's time zone")
    func cityTimeZones() {
        let days = Self.utcMidnights
        #expect(window.upcomingDays(days, in: Fixtures.lisbon, now: Self.aucklandEarlyMorning) == days)
        #expect(window.upcomingDays(days, in: Fixtures.auckland, now: Self.aucklandEarlyMorning) == Array(days.dropFirst()))
    }

    @Test("A city without a usable time zone uses the injected fallback")
    func fallbackTimeZone() {
        let days = Self.utcMidnights
        let aucklandFallback = UpcomingDaysWindow(dayCount: 7, fallbackTimeZone: Self.aucklandTimeZone)
        let lisbonFallback = UpcomingDaysWindow(dayCount: 7, fallbackTimeZone: Self.lisbonTimeZone)
        #expect(aucklandFallback.upcomingDays(days, in: Fixtures.noTimeZone, now: Self.aucklandEarlyMorning) == Array(days.dropFirst()))
        #expect(lisbonFallback.upcomingDays(days, in: Fixtures.noTimeZone, now: Self.aucklandEarlyMorning) == days)
        #expect(aucklandFallback.upcomingDays(days, in: Self.unknownZone, now: Self.aucklandEarlyMorning) == Array(days.dropFirst()))
    }

    @Test("A city's own time zone wins over the fallback")
    func cityZoneWins() {
        let aucklandFallback = UpcomingDaysWindow(dayCount: 7, fallbackTimeZone: Self.aucklandTimeZone)
        #expect(aucklandFallback.upcomingDays(Self.utcMidnights, in: Fixtures.lisbon, now: Self.aucklandEarlyMorning) == Self.utcMidnights)
    }

    @Test("Unsorted days come back in date order")
    func sorting() {
        let days = Fixtures.lisbonDays(from: 17, count: 5)
        #expect(window.upcomingDays(days.reversed(), in: Fixtures.lisbon, now: Fixtures.referenceNow) == days)
        #expect(window.upcomingDays([3, 0, 4, 1, 2].map { days[$0] }, in: Fixtures.lisbon, now: Fixtures.referenceNow) == days)
    }

    @Test("Only the earliest entry of each local day is kept")
    func duplicates() {
        let today = Fixtures.day(on: Fixtures.date(2026, 10, 17, in: "Europe/Lisbon"))
        let morning = Fixtures.day(on: Fixtures.date(2026, 10, 18, in: "Europe/Lisbon"), high: 18)
        let afternoon = Fixtures.day(on: Fixtures.date(2026, 10, 18, hour: 15, in: "Europe/Lisbon"), high: 26)
        let days = [today, afternoon, morning, morning, today]
        #expect(window.upcomingDays(days, in: Fixtures.lisbon, now: Fixtures.referenceNow) == [today, morning])
    }

    @Test("Duplicates are judged by the city's local calendar day")
    func localDuplicates() {
        let first = Fixtures.day(on: Fixtures.date(2026, 10, 17, hour: 11, in: "UTC"))
        let second = Fixtures.day(on: Fixtures.date(2026, 10, 18, hour: 10, in: "UTC"), high: 25)
        #expect(window.upcomingDays([second, first], in: Fixtures.auckland, now: Self.aucklandEarlyMorning) == [first])
        #expect(window.upcomingDays([second, first], in: Fixtures.lisbon, now: Self.aucklandEarlyMorning) == [first, second])
    }

    @Test("At most the configured number of days is returned, counted after dropping past days")
    func truncation() {
        let days = Fixtures.lisbonDays(from: 14, count: 12)
        #expect(window.dayCount == 7)
        #expect(window.upcomingDays(days, in: Fixtures.lisbon, now: Fixtures.referenceNow) == Array(days.dropFirst(3).prefix(7)))
        let shortWindow = UpcomingDaysWindow(dayCount: 2, fallbackTimeZone: Self.lisbonTimeZone)
        #expect(shortWindow.dayCount == 2)
        #expect(shortWindow.upcomingDays(days, in: Fixtures.lisbon, now: Fixtures.referenceNow) == Array(days.dropFirst(3).prefix(2)))
    }

    @Test("Fewer upcoming days than the day count are all returned")
    func fewerDays() {
        let days = Fixtures.lisbonDays(from: 17, count: 3)
        #expect(window.upcomingDays(days, in: Fixtures.lisbon, now: Fixtures.referenceNow) == days)
    }

    @Test("A day count of zero or less returns no days", arguments: [0, -1, -7])
    func nonPositiveDayCount(dayCount: Int) {
        let window = UpcomingDaysWindow(dayCount: dayCount, fallbackTimeZone: Self.lisbonTimeZone)
        #expect(window.dayCount == dayCount)
        #expect(window.upcomingDays(Fixtures.lisbonDays(from: 17, count: 7), in: Fixtures.lisbon, now: Fixtures.referenceNow).isEmpty)
    }

    @Test("Days on both sides of a daylight saving change stay separate")
    func daylightSaving() {
        let days = Fixtures.lisbonDays(from: 23, count: 7)
        let beforeChange = Fixtures.date(2026, 10, 23, hour: 8, in: "Europe/Lisbon")
        let afterChange = Fixtures.date(2026, 10, 26, hour: 8, in: "Europe/Lisbon")
        #expect(window.upcomingDays(days, in: Fixtures.lisbon, now: beforeChange) == days)
        #expect(window.upcomingDays(days, in: Fixtures.lisbon, now: afterChange) == Array(days.dropFirst(3)))
    }

    @Test("No days in gives no days out")
    func empty() {
        #expect(window.upcomingDays([], in: Fixtures.lisbon, now: Fixtures.referenceNow).isEmpty)
    }
}
