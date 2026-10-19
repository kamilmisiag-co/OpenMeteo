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
    private static let invisible: Set<Unicode.Scalar> = ["\u{200B}", "\u{FEFF}"]
    private static let standard = CitySearchQueryNormalizer(
        minimumLength: StandardRules.minimumQueryLength,
        separators: StandardRules.querySeparators,
        invisibleScalars: StandardRules.queryInvisibleScalars
    )
    private let normalizer = CitySearchQueryNormalizer(minimumLength: 2, separators: [","], invisibleScalars: invisible)

    @Test("Surrounding whitespace and newlines are trimmed", arguments: [
        ("\n\tLisbon\r\n", "Lisbon"),
        ("\u{00A0}Lisbon\u{2003}", "Lisbon"),
    ])
    func trimming(raw: String, expected: String) {
        #expect(normalizer.normalizedQuery(from: raw) == expected)
    }

    @Test("Empty and whitespace-only queries are rejected", arguments: ["", "\t \r\n "])
    func blank(raw: String) {
        #expect(normalizer.normalizedQuery(from: raw) == nil)
    }

    @Test("Only the text before the first separator is kept", arguments: [
        ("Lisbon , Lisbon, Portugal", "Lisbon"),
        ("  Rio de Janeiro ,Brazil", "Rio de Janeiro"),
    ])
    func separator(raw: String, expected: String) {
        #expect(normalizer.normalizedQuery(from: raw) == expected)
    }

    @Test("A query that starts with the separator has nothing left")
    func leadingSeparator() {
        #expect(normalizer.normalizedQuery(from: "  , Lisbon") == nil)
    }

    @Test("Every run of whitespace inside the query collapses into one space", arguments: [
        ("Rio   de \t Janeiro", "Rio de Janeiro"),
        ("San\u{00A0}\u{00A0}Francisco", "San Francisco"),
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
        ("e\u{301}", nil),
        ("🇵🇱🇵🇹", "🇵🇱🇵🇹"),
    ] as [(String, String?)])
    func characterCount(raw: String, expected: String?) {
        #expect(normalizer.normalizedQuery(from: raw) == expected)
    }

    @Test("Long names with diacritics are measured in characters, not scalars")
    func diacriticsAgainstLongerMinimum() {
        let normalizer = CitySearchQueryNormalizer(minimumLength: 5, separators: [","], invisibleScalars: Self.invisible)
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
        let normalizer = CitySearchQueryNormalizer(minimumLength: 4, separators: [","], invisibleScalars: Self.invisible)
        #expect(normalizer.normalizedQuery(from: "Rio") == nil)
        #expect(normalizer.normalizedQuery(from: "Rome") == "Rome")
    }

    @Test("A zero minimum still rejects a query with nothing left")
    func zeroMinimum() {
        let normalizer = CitySearchQueryNormalizer(minimumLength: 0, separators: [","], invisibleScalars: Self.invisible)
        #expect(normalizer.normalizedQuery(from: "") == nil)
        #expect(normalizer.normalizedQuery(from: "   ") == nil)
        #expect(normalizer.normalizedQuery(from: ", Lisbon") == nil)
        #expect(normalizer.normalizedQuery(from: "A") == "A")
    }

    @Test("The separator is configurable")
    func configurableSeparator() {
        let normalizer = CitySearchQueryNormalizer(minimumLength: 2, separators: ["/"], invisibleScalars: Self.invisible)
        #expect(normalizer.normalizedQuery(from: "Lisbon, Portugal") == "Lisbon, Portugal")
        #expect(normalizer.normalizedQuery(from: "Lisbon / Portugal") == "Lisbon")
        #expect(normalizer.normalizedQuery(from: "/Lisbon") == nil)
    }

    @Test("The standard separators cover the commas of other keyboards", arguments: ["，", "、", "､", "﹐", "﹑", "،"])
    func standardSeparators(separator: String) {
        #expect(Self.standard.normalizedQuery(from: "東京" + separator + "日本") == "東京")
        #expect(Self.standard.normalizedQuery(from: "Lisbon, Portugal") == "Lisbon")
    }

    @Test("The standard invisible characters are the zero-width space and the byte order mark")
    func standardInvisibleCharacters() {
        #expect(Self.standard.normalizedQuery(from: "Lis\u{200B}bon") == "Lisbon")
        #expect(Self.standard.normalizedQuery(from: "\u{FEFF}Porto\u{200B}") == "Porto")
        #expect(Self.standard.normalizedQuery(from: "\u{200B}L\u{FEFF}") == nil)
    }

    @Test("Only the injected invisible characters are removed, besides direction marks")
    func injectedInvisibleCharacters() {
        let wordJoiner = CitySearchQueryNormalizer(minimumLength: 2, separators: [","], invisibleScalars: ["\u{2060}"])
        let none = CitySearchQueryNormalizer(minimumLength: 2, separators: [","], invisibleScalars: [])

        #expect(wordJoiner.normalizedQuery(from: "Lis\u{2060}bon") == "Lisbon")
        #expect(wordJoiner.normalizedQuery(from: "\u{2060}L\u{2060}") == nil)
        #expect(wordJoiner.normalizedQuery(from: "Lis\u{200B}bon") == "Lis\u{200B}bon")
        #expect(none.normalizedQuery(from: "\u{FEFF}Porto") == "\u{FEFF}Porto")
        #expect(none.normalizedQuery(from: "Lis\u{2060}bon") == "Lis\u{2060}bon")
        #expect(none.normalizedQuery(from: "Lisboa\u{200F}, Portugal") == "Lisboa")
        #expect(none.normalizedQuery(from: "\u{2066}Porto\u{2069}") == "Porto")
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
        let normalizer = CitySearchQueryNormalizer(minimumLength: 2, separators: [",", "，", "،"], invisibleScalars: Self.invisible)
        #expect(normalizer.normalizedQuery(from: "東京，日本") == "東京")
        #expect(normalizer.normalizedQuery(from: "Lisboa، Portugal") == "Lisboa")
        #expect(normalizer.normalizedQuery(from: "Lisbon, Portugal") == "Lisbon")
        #expect(normalizer.normalizedQuery(from: "Lisbon; Portugal") == "Lisbon; Portugal")
    }
}
