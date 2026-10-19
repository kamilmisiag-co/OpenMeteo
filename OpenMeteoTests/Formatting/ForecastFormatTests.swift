//
//  ForecastFormatTests.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic
import Testing
@testable import OpenMeteo

@Suite("Forecast format")
@MainActor
struct ForecastFormatTests {
    private static let losAngeles = TimeZone(identifier: "America/Los_Angeles") ?? .gmt
    private static let tokyo = TimeZone(identifier: "Asia/Tokyo") ?? .gmt

    private let days = Fixtures.days(Fixtures.lisbonWeather)
    private let now = Fixtures.referenceNow
    private let noValue = String(localized: .formatNoValue)

    private func format(
        _ identifier: String,
        city: TimeZone = Fixtures.lisbonTimeZone,
        device: TimeZone = Fixtures.lisbonTimeZone
    ) -> ForecastFormat {
        ForecastFormat(locale: Locale(identifier: identifier), cityTimeZone: city, deviceTimeZone: device)
    }

    private func degrees(_ value: Int) -> String {
        String(localized: .formatDegrees(value))
    }

    @Test("Temperatures use the locale's unit unless Settings override it, rounded to whole degrees", arguments: [
        ("en_GB", 23.0, 23),
        ("en_US", 23.0, 73),
        ("en_GB@mu=fahrenhe", 23.0, 73),
        ("en_US@mu=celsius", 23.0, 23),
        ("en_GB", 22.5, 23),
        ("en_GB", -0.4, 0),
        ("en_GB", -3.6, -4),
        ("en_US", -40.0, -40),
    ])
    func temperature(locale: String, celsius: Double, expected: Int) {
        #expect(format(locale).temperature(celsius) == degrees(expected))
    }

    @Test("Wind is km/h in metric locales and mph in the UK and the US, unless Settings override it", arguments: [
        ("en_IE", "14 km/h"),
        ("en_GB", "9 mph"),
        ("en_US", "9 mph"),
        ("en_GB@ms=metric", "14 km/h"),
    ])
    func speed(locale: String, expected: String) {
        #expect(format(locale).speed(14) == expected)
    }

    @Test("Snowfall is in inches only in the US, unless Settings override it, keeps one decimal rounded half away from zero, and is never negative", arguments: [
        ("en_GB", 12.0, "12 cm"),
        ("en_US", 2.54, "1 in"),
        ("en_US@ms=metric", 12.0, "12 cm"),
        ("en_GB", 0.4, "0.4 cm"),
        ("en_US", 1.0, "0.4 in"),
        ("en_GB", 1.05, "1.1 cm"),
        ("en_GB", 0.25, "0.3 cm"),
        ("en_US", 0.0, "0 in"),
        ("en_GB", -0.01, "0 cm"),
        ("en_GB", -0.0, "0 cm"),
        ("en_GB", -0.5, "0 cm"),
        ("de_DE", 1.05, "1,1 cm"),
    ])
    func snowfall(locale: String, centimetres: Double, expected: String) {
        #expect(format(locale).snowfall(centimetres) == expected)
    }

    @Test("Percentages follow the locale and a missing chance has no value")
    func percent() {
        #expect(format("en_GB").percent(0.8) == "80%")
        #expect(format("de_DE").percent(0.8) == "80\u{00A0}%")
        #expect(format("en_GB").percent(0.004) == "0%")
        #expect(format("en_GB").percent(nil) == noValue)
    }

    @Test("Values that are not finite have no value")
    func nonFinite() {
        let english = format("en_GB")
        #expect(english.temperature(.nan) == noValue)
        #expect(english.speed(.infinity) == noValue)
        #expect(english.snowfall(.nan) == noValue)
        #expect(english.percent(.nan) == noValue)
    }

    @Test("Today and day names follow the city's time zone, not the device's")
    func cityDays() {
        let today = String(localized: .dayToday)
        let lisbon = format("en_GB", city: Fixtures.lisbonTimeZone, device: Self.losAngeles)
        #expect(lisbon.isToday(days[0].date, now: now))
        #expect(lisbon.shortDay(days[0].date, now: now) == today)
        #expect(lisbon.shortDay(days[1].date, now: now) == "Fri")
        #expect(lisbon.day(days[0].date, now: now) == today)
        #expect(lisbon.day(days[2].date, now: now) == "Sat 17")
        #expect(lisbon.dayWithDate(days[0].date) == "Thu 15")

        let losAngeles = format("en_GB", city: Self.losAngeles, device: Fixtures.lisbonTimeZone)
        #expect(!losAngeles.isToday(days[0].date, now: now))
        #expect(losAngeles.shortDay(days[0].date, now: now) == "Wed")
        #expect(losAngeles.dayWithDate(days[0].date) == "Wed 14")
    }

    @Test("Spoken days, initials and weekdays follow the locale")
    func dayNames() {
        let english = format("en_GB")
        #expect(english.spokenDay(days[2].date) == "Saturday 17")
        #expect(english.dayInitial(days[5].date) == "T")
        #expect(english.weekday(days[5].date) == "Tue")

        let german = format("de_DE")
        #expect(german.dayInitial(days[5].date) == "D")
        #expect(german.weekday(days[0].date) == "Do")
    }

    @Test("Times follow the device's time zone, not the city's")
    func deviceTimes() {
        #expect(format("en_GB", city: Self.tokyo, device: Fixtures.lisbonTimeZone).time(now) == "09:42")
        #expect(format("en_GB", city: Fixtures.lisbonTimeZone, device: Self.tokyo).time(now) == "17:42")
        #expect(format("en_GB").dayAndTime(now) == "Thu 15, 09:42")
    }

    @Test("Timestamps add the day only when it is not today on the device")
    func timestamp() {
        let lisbon = format("en_GB")
        let tokyo = format("en_GB", device: Self.tokyo)
        let earlierToday = now.addingTimeInterval(-2 * 3600)
        let lateLastNight = now.addingTimeInterval(-10 * 3600)
        #expect(lisbon.timestamp(earlierToday, now: now) == "07:42")
        #expect(lisbon.timestamp(lateLastNight, now: now) == "Wed 14, 23:42")
        #expect(tokyo.timestamp(lateLastNight, now: now) == "07:42")
    }

    @Test("Lists join items with the locale's conjunction", arguments: [
        ("en_GB", ["rain", "wind", "temperature"], "rain, wind and temperature"),
        ("en_US", ["rain", "wind", "temperature"], "rain, wind, and temperature"),
        ("de_DE", ["Regen", "Wind"], "Regen und Wind"),
        ("en_GB", ["rain"], "rain"),
        ("en_GB", [], ""),
    ])
    func list(locale: String, items: [String], expected: String) {
        #expect(format(locale).list(items) == expected)
    }
}
