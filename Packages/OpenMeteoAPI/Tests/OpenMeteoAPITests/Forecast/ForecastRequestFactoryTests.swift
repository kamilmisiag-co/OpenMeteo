//
//  ForecastRequestFactoryTests.swift
//  OpenMeteoAPITests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic
import LogicMocks
import OpenMeteoAPI
import Synchronization
import Testing

@Suite("Forecast request factory")
struct ForecastRequestFactoryTests {
    private final class RecordingDayCounts: ForecastDayCounting {
        private let received = Mutex<[Int]>([])
        private let requestedDays: Int

        init(returning requestedDays: Int) {
            self.requestedDays = requestedDays
        }

        var upcomingDayCounts: [Int] {
            received.withLock { $0 }
        }

        func requestedDays(forUpcomingDays dayCount: Int) -> Int {
            received.withLock { $0.append(dayCount) }
            return requestedDays
        }
    }

    @Test("A city with a known IANA time zone asks for that zone", arguments: ["Pacific/Auckland"])
    func knownTimeZone(identifier: String) {
        let endpoint = makeFactory().request(for: city(timeZoneIdentifier: identifier), upcomingDays: 7)
        #expect(endpoint.timeZoneIdentifier == identifier)
        #expect(endpoint.latitude == 1)
        #expect(endpoint.longitude == 2)
    }

    @Test(
        "A city without a usable time zone asks for the injected fallback",
        arguments: [nil, "", "Mars/Olympus"] as [String?], ["UTC"]
    )
    func timeZoneFallback(identifier: String?, fallback: String) {
        let endpoint = makeFactory(fallbackTimeZoneIdentifier: fallback).request(for: city(timeZoneIdentifier: identifier), upcomingDays: 7)
        #expect(endpoint.timeZoneIdentifier == fallback)
        #expect(endpoint.latitude == 1)
        #expect(endpoint.longitude == 2)
    }

    @Test("The day count is whatever the injected day counter answers for the upcoming days", arguments: [(7, 42)])
    func injectedDayCount(upcomingDays: Int, answer: Int) {
        let dayCounts = RecordingDayCounts(returning: answer)
        let endpoint = makeFactory(dayCounts: dayCounts).request(for: SampleCities.zakopane, upcomingDays: upcomingDays)
        #expect(endpoint.dayCount == answer)
        #expect(dayCounts.upcomingDayCounts == [upcomingDays])
    }

    private func makeFactory(
        dayCounts: any ForecastDayCounting = RecordingDayCounts(returning: 8),
        fallbackTimeZoneIdentifier: String = Fixtures.automaticTimeZoneIdentifier
    ) -> ForecastRequestFactory {
        ForecastRequestFactory(dayCounts: dayCounts, fallbackTimeZoneIdentifier: fallbackTimeZoneIdentifier)
    }

    private func city(timeZoneIdentifier: String?) -> City {
        City(
            id: 7, name: "Somewhere", region: nil, country: "Nowhere", countryCode: nil,
            latitude: 1, longitude: 2, timeZoneIdentifier: timeZoneIdentifier
        )
    }
}
