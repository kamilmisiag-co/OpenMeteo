//
//  CitySearchQueryNormalizerTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic
import Testing

@Suite("City search query normalizer")
struct CitySearchQueryNormalizerTests {
    private let normalizer = CitySearchQueryNormalizer(minimumLength: 2, separators: [","])

    @Test("Surrounding whitespace and newlines are trimmed", arguments: [
        ("Lisbon", "Lisbon"),
        ("  Lisbon  ", "Lisbon"),
        ("\n\tLisbon\r\n", "Lisbon"),
        ("\u{00A0}Lisbon\u{2003}", "Lisbon"),
    ])
    func trimming(raw: String, expected: String) {
        #expect(normalizer.normalizedQuery(from: raw) == expected)
    }

    @Test("Empty and whitespace-only queries are rejected", arguments: ["", " ", "     ", "\n", "\t \r\n ", "\u{00A0}\u{2003}"])
    func blank(raw: String) {
        #expect(normalizer.normalizedQuery(from: raw) == nil)
    }

    @Test("Only the text before the first separator is kept", arguments: [
        ("Lisbon, Portugal", "Lisbon"),
        ("Lisbon,Portugal", "Lisbon"),
        ("Lisbon , Lisbon, Portugal", "Lisbon"),
        ("Lisbon,", "Lisbon"),
        ("  Rio de Janeiro ,Brazil", "Rio de Janeiro"),
        ("Bergen\n, Norway", "Bergen"),
    ])
    func separator(raw: String, expected: String) {
        #expect(normalizer.normalizedQuery(from: raw) == expected)
    }

    @Test("A query that starts with the separator has nothing left", arguments: [",", ",Lisbon", ", Lisbon", "  , Lisbon", ",,Lisbon", "\n,Lisbon, Portugal"])
    func leadingSeparator(raw: String) {
        #expect(normalizer.normalizedQuery(from: raw) == nil)
    }

    @Test("Every run of whitespace inside the query collapses into one space", arguments: [
        ("Rio   de \t Janeiro", "Rio de Janeiro"),
        ("New\nYork", "New York"),
        ("Los \r\n Angeles", "Los Angeles"),
        ("San\u{00A0}\u{00A0}Francisco", "San Francisco"),
        ("  Buenos \n\n Aires  , Argentina", "Buenos Aires"),
    ])
    func internalWhitespace(raw: String, expected: String) {
        #expect(normalizer.normalizedQuery(from: raw) == expected)
    }

    @Test("Queries shorter than the minimum are rejected and exactly the minimum is accepted")
    func minimumLength() {
        #expect(normalizer.normalizedQuery(from: "L") == nil)
        #expect(normalizer.normalizedQuery(from: "  L  ") == nil)
        #expect(normalizer.normalizedQuery(from: "L, isbon") == nil)
        #expect(normalizer.normalizedQuery(from: "Li") == "Li")
        #expect(normalizer.normalizedQuery(from: " Li , sbon") == "Li")
        #expect(normalizer.normalizedQuery(from: "A B") == "A B")
    }

    @Test("Length counts characters, so letters with diacritics and emoji count once", arguments: [
        ("Ł", nil),
        ("e\u{301}", nil),
        ("🇵🇱", nil),
        ("👨‍👩‍👧", nil),
        ("Łó", "Łó"),
        ("e\u{301}e\u{301}", "e\u{301}e\u{301}"),
        ("🇵🇱🇵🇹", "🇵🇱🇵🇹"),
    ] as [(String, String?)])
    func characterCount(raw: String, expected: String?) {
        #expect(normalizer.normalizedQuery(from: raw) == expected)
    }

    @Test("Long names with diacritics are measured in characters, not scalars")
    func diacriticsAgainstLongerMinimum() {
        let normalizer = CitySearchQueryNormalizer(minimumLength: 5, separators: [","])
        #expect(normalizer.normalizedQuery(from: "Łódź") == nil)
        #expect(normalizer.normalizedQuery(from: "Lo\u{301}dz\u{301}") == nil)
        #expect(normalizer.normalizedQuery(from: "Kraków") == "Kraków")
        #expect(normalizer.normalizedQuery(from: "Zu\u{308}rich, Switzerland") == "Zu\u{308}rich")
    }

    @Test("Case and diacritics are kept as typed")
    func preservesText() {
        #expect(normalizer.normalizedQuery(from: "ZÜRICH") == "ZÜRICH")
        #expect(normalizer.normalizedQuery(from: "são paulo, Brazil") == "são paulo")
    }

    @Test("The minimum length is configurable")
    func configurableMinimum() {
        let normalizer = CitySearchQueryNormalizer(minimumLength: 4, separators: [","])
        #expect(normalizer.normalizedQuery(from: "Rio") == nil)
        #expect(normalizer.normalizedQuery(from: "Rome") == "Rome")
    }

    @Test("A zero or negative minimum still rejects a query with nothing left", arguments: [0, -1])
    func nonPositiveMinimum(minimumLength: Int) {
        let normalizer = CitySearchQueryNormalizer(minimumLength: minimumLength, separators: [","])
        #expect(normalizer.normalizedQuery(from: "") == nil)
        #expect(normalizer.normalizedQuery(from: "   ") == nil)
        #expect(normalizer.normalizedQuery(from: ", Lisbon") == nil)
        #expect(normalizer.normalizedQuery(from: "A") == "A")
    }

    @Test("The separator is configurable")
    func configurableSeparator() {
        let normalizer = CitySearchQueryNormalizer(minimumLength: 2, separators: ["/"])
        #expect(normalizer.normalizedQuery(from: "Lisbon, Portugal") == "Lisbon, Portugal")
        #expect(normalizer.normalizedQuery(from: "Lisbon / Portugal") == "Lisbon")
        #expect(normalizer.normalizedQuery(from: "/Lisbon") == nil)
    }

    @Test("The standard separators cover the commas of other keyboards", arguments: ["，", "、", "､", "﹐", "﹑", "،"])
    func standardSeparators(separator: String) {
        let normalizer = CitySearchQueryNormalizer(minimumLength: StandardRules.minimumQueryLength, separators: StandardRules.querySeparators)
        #expect(normalizer.normalizedQuery(from: "東京" + separator + "日本") == "東京")
        #expect(normalizer.normalizedQuery(from: "Lisbon, Portugal") == "Lisbon")
    }

    @Test("Invisible direction marks and zero-width characters are removed before measuring")
    func invisibleCharacters() {
        #expect(normalizer.normalizedQuery(from: "Lisboa\u{200F}, Portugal") == "Lisboa")
        #expect(normalizer.normalizedQuery(from: "\u{FEFF}Porto") == "Porto")
        #expect(normalizer.normalizedQuery(from: "Lis\u{200B}bon") == "Lisbon")
        #expect(normalizer.normalizedQuery(from: "\u{200F}L") == nil)
        #expect(normalizer.normalizedQuery(from: "\u{2066}Porto\u{2069}") == "Porto")
    }

    @Test("Any of several separators ends the query, so commas from other keyboards work too")
    func severalSeparators() {
        let normalizer = CitySearchQueryNormalizer(minimumLength: 2, separators: [",", "，", "،"])
        #expect(normalizer.normalizedQuery(from: "東京，日本") == "東京")
        #expect(normalizer.normalizedQuery(from: "Lisboa، Portugal") == "Lisboa")
        #expect(normalizer.normalizedQuery(from: "Lisbon, Portugal") == "Lisbon")
        #expect(normalizer.normalizedQuery(from: "Lisbon; Portugal") == "Lisbon; Portugal")
    }
}
