//
//  SafeFileNameEncoderTests.swift
//  StorageTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Storage
import Testing

@Suite("Safe file name encoder")
struct SafeFileNameEncoderTests {
    @Test("The configured extension is the one appended")
    func configuredExtension() {
        #expect(SafeFileNameEncoder(fileExtension: "plist").fileName(forKey: "recent-cities") == "recent-cities.plist")
    }

    @Test("An empty extension leaves the key as the whole file name")
    func emptyExtension() {
        let encoder = SafeFileNameEncoder(fileExtension: "")
        #expect(encoder.fileName(forKey: "recent-cities") == "recent-cities")
        #expect(encoder.fileName(forKey: "weather-3161732") == "weather-3161732")
    }
}
