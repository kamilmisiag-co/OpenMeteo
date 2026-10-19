//
//  CityDisplayTests.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic
import Testing
@testable import OpenMeteo

@Suite("City display")
@MainActor
struct CityDisplayTests {
    @Test("Subtitle joins the region and the country")
    func regionAndCountry() {
        #expect(Fixtures.zakopane.subtitle == String(localized: .citySubtitle("Lesser Poland", "Poland")))
    }

    @Test("Subtitle without a region is the country", arguments: [nil, "", "   "] as [String?])
    func missingRegion(region: String?) {
        #expect(city(region: region, country: "Atlantis").subtitle == "Atlantis")
    }

    @Test("Subtitle without a country is the region")
    func missingCountry() {
        #expect(city(region: "Vestland", country: " ").subtitle == "Vestland")
    }

    @Test("Surrounding spaces are trimmed from the region and the country")
    func trimmedParts() {
        #expect(city(region: " Vestland ", country: " Norway ").subtitle == String(localized: .citySubtitle("Vestland", "Norway")))
    }

    @Test("Flag is the country code's regional indicator flag")
    func flag() {
        #expect(city(countryCode: "PT").flag == "🇵🇹")
    }

    @Test("No flag without a country code")
    func noFlag() {
        #expect(city(countryCode: nil).flag == nil)
    }

    private func city(region: String? = nil, country: String = "Atlantis", countryCode: String? = nil) -> City {
        City(
            id: 1, name: "Somewhere", region: region, country: country, countryCode: countryCode,
            latitude: 0, longitude: 0, timeZoneIdentifier: nil
        )
    }
}
