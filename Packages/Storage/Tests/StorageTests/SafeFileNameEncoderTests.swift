//
//  SafeFileNameEncoderTests.swift
//  StorageTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Storage
import Testing

@Suite("Safe file name encoder")
struct SafeFileNameEncoderTests {
    @Test(
        "Keys made of letters, digits, hyphens and underscores keep their name and gain the extension",
        arguments: ["weather-2267057", "recent-cities", "Recent_Cities_2", "ABCxyz019", "a", "7", "-", "_", "--__"]
    )
    func allowedKeys(key: String) throws {
        #expect(try Fixtures.standardFileNames.fileName(forKey: key) == key + ".json")
    }

    @Test("The configured extension is the one appended")
    func configuredExtension() throws {
        let encoder = SafeFileNameEncoder(allowedCharacters: StorageStandard.allowedKeyCharacters, fileExtension: "plist")
        #expect(try encoder.fileName(forKey: "recent-cities") == "recent-cities.plist")
    }

    @Test("An empty extension leaves the key as the whole file name")
    func emptyExtension() throws {
        let encoder = SafeFileNameEncoder(allowedCharacters: StorageStandard.allowedKeyCharacters, fileExtension: "")
        #expect(try encoder.fileName(forKey: "recent-cities") == "recent-cities")
        #expect(try encoder.fileName(forKey: "weather-3161732") == "weather-3161732")
    }

    @Test("The injected character set decides which keys are allowed")
    func injectedCharacters() throws {
        let encoder = SafeFileNameEncoder(allowedCharacters: CharacterSet(charactersIn: "xyz."), fileExtension: "txt")
        #expect(try encoder.fileName(forKey: "x.y.z") == "x.y.z.txt")
        #expect(throws: StorageError.invalidKey("abc")) {
            try encoder.fileName(forKey: "abc")
        }
        #expect(throws: StorageError.invalidKey("x-y")) {
            try encoder.fileName(forKey: "x-y")
        }
    }

    @Test("An empty key is rejected even with an empty extension")
    func emptyKey() {
        #expect(throws: StorageError.invalidKey("")) {
            try Fixtures.standardFileNames.fileName(forKey: "")
        }
        #expect(throws: StorageError.invalidKey("")) {
            try SafeFileNameEncoder(allowedCharacters: StorageStandard.allowedKeyCharacters, fileExtension: "").fileName(forKey: "")
        }
    }

    @Test(
        "Keys that could point outside the storage directory are rejected",
        arguments: ["..", "../x", "a/b", ".", "/", "/etc/passwd", "./weather-1", "weather-1/..", "a\\b", "~", "a%2Fb", "weather-1.json"]
    )
    func pathTraversal(key: String) {
        #expect(throws: StorageError.invalidKey(key)) {
            try Fixtures.standardFileNames.fileName(forKey: key)
        }
    }

    @Test(
        "Keys with spaces or control characters are rejected",
        arguments: [" ", "recent cities", " weather-1", "weather-1 ", "key\n", "tab\tkey", "nul\u{0}key", "no\u{00A0}break"]
    )
    func whitespace(key: String) {
        #expect(throws: StorageError.invalidKey(key)) {
            try Fixtures.standardFileNames.fileName(forKey: key)
        }
    }

    @Test(
        "Keys with non-ASCII letters, digits or emoji are rejected",
        arguments: ["Kraków", "Zürich", "東京", "Москва", "cafe\u{301}", "ｗｅａｔｈｅｒ", "weather-٣", "weather-☀️", "🌧", "👨‍👩‍👧"]
    )
    func nonASCII(key: String) {
        #expect(throws: StorageError.invalidKey(key)) {
            try Fixtures.standardFileNames.fileName(forKey: key)
        }
    }
}
