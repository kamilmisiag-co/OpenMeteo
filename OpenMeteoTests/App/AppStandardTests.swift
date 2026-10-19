//
//  AppStandardTests.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 19/10/2026.
//

import Foundation
import Testing
@testable import OpenMeteo

@Suite("App standard")
@MainActor
struct AppStandardTests {
    @Test("The attribution links point at Open-Meteo, the CC BY 4.0 licence and GeoNames")
    func attributionLinks() {
        #expect(AppStandard.openMeteoURL.absoluteString == "https://open-meteo.com")
        #expect(AppStandard.licenceURL.absoluteString == "https://creativecommons.org/licenses/by/4.0/")
        #expect(AppStandard.geoNamesURL.absoluteString == "https://www.geonames.org")
    }
}
