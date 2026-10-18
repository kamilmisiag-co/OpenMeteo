//
//  StorageStandardTests.swift
//  StorageTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic
import Storage
import Testing

@Suite("Storage standard")
struct StorageStandardTests {
    @Test("Directory names are pinned")
    func directoryNames() {
        #expect(StorageStandard.weatherCacheDirectoryName == "WeatherCache")
        #expect(StorageStandard.recentCitiesDirectoryName == "RecentCities")
    }

    @Test("Keys and the file extension are pinned")
    func keysAndExtension() {
        #expect(StorageStandard.weatherKeyPrefix == "weather-")
        #expect(StorageStandard.recentCitiesKey == "recent-cities")
        #expect(StorageStandard.fileExtension == "json")
    }

    @Test("Allowed key characters are exactly ASCII letters, digits, hyphen and underscore")
    func allowedCharactersAreExact() {
        let members = (UInt32(0)...0x10FFFF)
            .lazy
            .compactMap { Unicode.Scalar($0) }
            .filter { StorageStandard.allowedKeyCharacters.contains($0) }
        #expect(String(String.UnicodeScalarView(members)) == "-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz")
    }

    @Test("The standard recent-cities key is a valid file name under the standard encoder")
    func recentCitiesKeyIsValid() throws {
        #expect(try Fixtures.standardFileNames.fileName(forKey: StorageStandard.recentCitiesKey) == "recent-cities.json")
    }

    @Test("A standard weather key for a real city id is a valid file name under the standard encoder", arguments: [
        (Fixtures.lisbon, "weather-2267057.json"),
        (Fixtures.bergen, "weather-3161732.json"),
        (Fixtures.zakopane, "weather-3080866.json"),
    ])
    func weatherKeyIsValid(city: City, expected: String) throws {
        let key = PrefixedCityKey(prefix: StorageStandard.weatherKeyPrefix).key(for: city)
        #expect(try Fixtures.standardFileNames.fileName(forKey: key) == expected)
    }
}
