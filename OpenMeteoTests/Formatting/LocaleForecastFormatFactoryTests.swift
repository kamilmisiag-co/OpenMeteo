//
//  LocaleForecastFormatFactoryTests.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic
import Testing
@testable import OpenMeteo

@Suite("Locale forecast format factory")
@MainActor
struct LocaleForecastFormatFactoryTests {
    private static let tokyo = TimeZone(identifier: "Asia/Tokyo")!
    private static let losAngeles = TimeZone(identifier: "America/Los_Angeles")!

    private let firstDay = Fixtures.days(Fixtures.lisbonWeather)[0].date

    @Test("Formats for a city use its time zone for days and the device's for times")
    func cityAndDeviceTimeZones() {
        let factory = LocaleForecastFormatFactory(locale: Fixtures.locale, deviceTimeZone: Self.tokyo, fallbackTimeZone: Fixtures.lisbonTimeZone)

        let format = factory.format(for: PreviewCities.lisbonOhio)

        #expect(format.dayWithDate(firstDay) == "Wed 14")
        #expect(format.time(Fixtures.referenceNow) == "17:42")
    }

    @Test("Formats for a city without a time zone use the fallback time zone for days")
    func fallbackTimeZone() {
        let factory = LocaleForecastFormatFactory(locale: Fixtures.locale, deviceTimeZone: Self.tokyo, fallbackTimeZone: Self.losAngeles)

        let format = factory.format(for: Fixtures.nowhere)

        #expect(format.dayWithDate(firstDay) == "Wed 14")
        #expect(format.time(Fixtures.referenceNow) == "17:42")
    }
}
