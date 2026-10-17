//
//  ForecastRequestFactoryTests.swift
//  OpenMeteoAPITests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic
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

    @Test("The request carries the city's coordinates and time zone")
    func cityRequest() {
        let endpoint = makeFactory().request(for: Fixtures.zakopane, upcomingDays: 7)
        #expect(endpoint.latitude == 49.2992)
        #expect(endpoint.longitude == 19.9496)
        #expect(endpoint.timeZoneIdentifier == "Europe/Warsaw")
    }

    @Test("A city with a known IANA time zone asks for that zone", arguments: ["Europe/Warsaw", "Pacific/Auckland", "America/New_York", "Europe/Lisbon"])
    func knownTimeZone(identifier: String) {
        let endpoint = makeFactory().request(for: city(timeZoneIdentifier: identifier), upcomingDays: 7)
        #expect(endpoint.timeZoneIdentifier == identifier)
        #expect(endpoint.latitude == 1)
        #expect(endpoint.longitude == 2)
    }

    @Test(
        "A city without a usable time zone asks for the injected fallback",
        arguments: [nil, "", "  ", "Mars/Olympus"] as [String?], ["auto", "UTC"]
    )
    func timeZoneFallback(identifier: String?, fallback: String) {
        let endpoint = makeFactory(fallbackTimeZoneIdentifier: fallback).request(for: city(timeZoneIdentifier: identifier), upcomingDays: 7)
        #expect(endpoint.timeZoneIdentifier == fallback)
        #expect(endpoint.latitude == 1)
        #expect(endpoint.longitude == 2)
    }

    @Test("The fixture city without a time zone asks for the injected fallback", arguments: ["auto", "UTC"])
    func noTimeZoneFixture(fallback: String) {
        let endpoint = makeFactory(fallbackTimeZoneIdentifier: fallback).request(for: Fixtures.noTimeZone, upcomingDays: 7)
        #expect(endpoint.timeZoneIdentifier == fallback)
        #expect(endpoint.latitude == 0)
        #expect(endpoint.longitude == 0)
    }

    @Test("The day count is whatever the injected day counter answers for the upcoming days", arguments: [(7, 42), (0, 3), (-4, 1), (Int.max, 16)])
    func injectedDayCount(upcomingDays: Int, answer: Int) {
        let dayCounts = RecordingDayCounts(returning: answer)
        let endpoint = makeFactory(dayCounts: dayCounts).request(for: Fixtures.zakopane, upcomingDays: upcomingDays)
        #expect(endpoint.dayCount == answer)
        #expect(dayCounts.upcomingDayCounts == [upcomingDays])
    }

    @Test("The day counter is asked once for every request")
    func dayCounterAskedPerRequest() {
        let dayCounts = RecordingDayCounts(returning: 5)
        let factory = makeFactory(dayCounts: dayCounts)
        #expect(dayCounts.upcomingDayCounts.isEmpty)

        _ = factory.request(for: Fixtures.zakopane, upcomingDays: 7)
        _ = factory.request(for: Fixtures.noTimeZone, upcomingDays: 3)

        #expect(dayCounts.upcomingDayCounts == [7, 3])
    }

    @Test(
        "The standard factory asks for one extra day, never more than sixteen, and lets the server pick a missing zone",
        arguments: [(Fixtures.zakopane, 7, 8, "Europe/Warsaw"), (Fixtures.zakopane, 16, 16, "Europe/Warsaw"), (Fixtures.noTimeZone, 0, 1, "auto")]
    )
    func standardFactory(city: City, upcomingDays: Int, expectedDays: Int, expectedTimeZone: String) {
        let endpoint = Fixtures.forecastRequests().request(for: city, upcomingDays: upcomingDays)
        #expect(endpoint.dayCount == expectedDays)
        #expect(endpoint.timeZoneIdentifier == expectedTimeZone)
        #expect(endpoint.latitude == city.latitude)
        #expect(endpoint.longitude == city.longitude)
    }

    private func makeFactory(
        dayCounts: any ForecastDayCounting = RecordingDayCounts(returning: 8),
        fallbackTimeZoneIdentifier: String = OpenMeteoStandard.timeZoneFallbackIdentifier
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
