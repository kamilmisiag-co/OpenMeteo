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
    @Test("Formats for a city use its time zone for days and the device's for times")
    func cityAndDeviceTimeZones() {
        let tokyo = TimeZone(identifier: "Asia/Tokyo") ?? .gmt
        let losAngeles = TimeZone(identifier: "America/Los_Angeles") ?? .gmt
        let factory = LocaleForecastFormatFactory(locale: Fixtures.locale, deviceTimeZone: tokyo)
        let firstDay = Fixtures.days(Fixtures.lisbonWeather)[0].date

        let format = factory.format(forCityIn: losAngeles)

        #expect(format.dayWithDate(firstDay) == "Wed 14")
        #expect(format.time(Fixtures.referenceNow) == "17:42")
    }

    @Test("Formats use the factory's locale for units")
    func locale() {
        let factory = LocaleForecastFormatFactory(locale: Locale(identifier: "en_US"), deviceTimeZone: Fixtures.lisbonTimeZone)

        let format = factory.format(forCityIn: Fixtures.lisbonTimeZone)

        #expect(format.temperature(23) == "73°")
        #expect(format.speed(14) == "9 mph")
    }
}
