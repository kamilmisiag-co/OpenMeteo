//
//  GregorianDayKeyParserTests.swift
//  OpenMeteoAPITests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import OpenMeteoAPI
import Testing
import Utils

@Suite("Gregorian day key parser")
struct GregorianDayKeyParserTests {
    private let parser = GregorianDayKeyParser()

    @Test(
        "The day key of a daily or hourly timestamp is its text before the time",
        arguments: [("2026-10-17", "2026-10-17"), ("2026-10-17T05:00", "2026-10-17"), ("2026-10-18T23:00", "2026-10-18")]
    )
    func dayKey(timestamp: String, expected: String) {
        #expect(parser.dayKey(of: timestamp) == expected)
    }

    @Test(
        "A day key's local midnight is the start of that date in the requested zone",
        arguments: [
            ("Europe/Warsaw", "2026-10-16T22:00:00Z"),
            ("America/New_York", "2026-10-17T04:00:00Z"),
            ("Pacific/Auckland", "2026-10-16T11:00:00Z"),
        ]
    )
    func localMidnight(identifier: String, instant: String) throws {
        let timeZone = try #require(TimeZone(identifier: identifier))
        let expected = try Fixtures.localMidnight(2026, 10, 17, in: identifier)
        let expectedInstant = try Self.instant(instant)
        let midnight = parser.localMidnight(ofDayKey: "2026-10-17", in: timeZone)
        #expect(midnight == expected)
        #expect(midnight == expectedInstant)
    }

    @Test(
        "A malformed or impossible day key has no local midnight",
        arguments: [
            "2026-02-30", "2026-10", "garbage", "", "2026-13-01", "2026-10-00",
            "2026-02-29", "2026-10-17T05:00", "2026-10-17-01", "2026--17",
            "+2026-+10-+17", "2026-1-5", "2026-10-7", "02026-10-17", "2026-١٠-١٧",
            "+026-10-17", "2026-+1-17", "2026-10-+7", "2026-10-1\u{FF17}",
        ]
    )
    func malformedDayKey(dayKey: String) {
        #expect(parser.localMidnight(ofDayKey: dayKey, in: .gmt) == nil)
    }

    @Test("A leap day is a valid day key in a leap year")
    func leapDay() throws {
        let expected = try Self.instant("2028-02-29T00:00:00Z")
        #expect(parser.localMidnight(ofDayKey: "2028-02-29", in: .gmt) == expected)
    }

    @Test("The day on which Warsaw leaves summer time lasts twenty-five hours between local midnights")
    func daylightSavingWeek() throws {
        let warsaw = try #require(TimeZone(identifier: "Europe/Warsaw"))
        let calendar = Calendar.gregorian(timeZone: warsaw)
        let midnights = try (24...27).map { day in
            try #require(parser.localMidnight(ofDayKey: "2026-10-\(day)", in: warsaw))
        }
        let expected = try (24...27).map { try Fixtures.localMidnight(2026, 10, $0, in: "Europe/Warsaw") }
        let lastSummerMidnight = try Self.instant("2026-10-24T22:00:00Z")
        let firstWinterMidnight = try Self.instant("2026-10-25T23:00:00Z")
        #expect(midnights == expected)
        #expect(midnights.allSatisfy { calendar.startOfDay(for: $0) == $0 })
        #expect(midnights[1] == lastSummerMidnight)
        #expect(midnights[2] == firstWinterMidnight)
        #expect(midnights[1].timeIntervalSince(midnights[0]) == 24 * 60 * 60)
        #expect(midnights[2].timeIntervalSince(midnights[1]) == 25 * 60 * 60)
        #expect(midnights[3].timeIntervalSince(midnights[2]) == 24 * 60 * 60)
    }

    @Test(
        "A day key is read as a Gregorian date whatever the requested zone",
        arguments: ["Europe/Warsaw", "Pacific/Kiritimati", "Pacific/Pago_Pago", "Asia/Tokyo", "GMT"], [2026, 2569]
    )
    func gregorianInEveryZone(identifier: String, year: Int) throws {
        let timeZone = try #require(TimeZone(identifier: identifier))
        let expected = try Fixtures.localMidnight(year, 10, 17, in: identifier)
        let midnight = try #require(parser.localMidnight(ofDayKey: "\(year)-10-17", in: timeZone))
        let components = Calendar.gregorian(timeZone: timeZone).dateComponents([.year, .month, .day, .hour, .minute, .second], from: midnight)
        #expect(midnight == expected)
        #expect(components == DateComponents(year: year, month: 10, day: 17, hour: 0, minute: 0, second: 0))
    }

    private static func instant(_ text: String) throws -> Date {
        try Date(text, strategy: .iso8601)
    }
}
