//
//  GeocodingRequestFactoryTests.swift
//  OpenMeteoAPITests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Networking
import OpenMeteoAPI
import Synchronization
import Testing

@Suite("Geocoding request factory")
struct GeocodingRequestFactoryTests {
    private final class SequencedLanguageCodes: LanguageCodeProviding {
        private let state: Mutex<(remaining: [String], calls: Int)>

        init(_ codes: [String]) {
            state = Mutex((remaining: codes, calls: 0))
        }

        var callCount: Int {
            state.withLock { $0.calls }
        }

        func languageCode() -> String {
            state.withLock { state in
                state.calls += 1
                return state.remaining.isEmpty ? "" : state.remaining.removeFirst()
            }
        }
    }

    @Test("The searched name is sent unchanged", arguments: ["Lisbon", "São Paulo", "Sao+Paulo", "Biel/Bienne", "  Kraków  ", ""])
    func namePassesThrough(name: String) {
        let endpoint = makeFactory(resultLimit: 10, languageCodes: SequencedLanguageCodes(["en"])).request(forName: name)
        #expect(endpoint.name == name)
    }

    @Test(
        "The result limit is clamped to the API's range of 1 to 100",
        arguments: [(0, 1), (-5, 1), (Int.min, 1), (1, 1), (10, 10), (100, 100), (101, 100), (Int.max, 100)]
    )
    func standardRangeLimit(resultLimit: Int, expected: Int) {
        let endpoint = makeFactory(resultLimit: resultLimit, languageCodes: SequencedLanguageCodes(["en"])).request(forName: "Lisbon")
        #expect(endpoint.resultLimit == expected)
    }

    @Test(
        "The result limit is clamped to whatever range is injected",
        arguments: [(0, 5), (4, 5), (5, 5), (12, 12), (20, 20), (21, 20), (Int.max, 20)]
    )
    func customRangeLimit(resultLimit: Int, expected: Int) {
        let factory = GeocodingRequestFactory(resultLimit: resultLimit, allowedResultLimits: 5...20, languageCodes: SequencedLanguageCodes(["en"]))
        #expect(factory.request(forName: "Lisbon").resultLimit == expected)
    }

    @Test("A single-value range always sends that value")
    func singleValueRange() {
        let factory = GeocodingRequestFactory(resultLimit: 50, allowedResultLimits: 3...3, languageCodes: SequencedLanguageCodes(["en"]))
        #expect(factory.request(forName: "Lisbon").resultLimit == 3)
    }

    @Test("Every request from one factory carries the same clamped limit")
    func limitIsStable() {
        let factory = makeFactory(resultLimit: 250, languageCodes: SequencedLanguageCodes(["en", "pl", "pt"]))
        let limits = ["Lisbon", "Lizbona", "Lisboa"].map { factory.request(forName: $0).resultLimit }
        #expect(limits == [100, 100, 100])
    }

    @Test("The language comes from the injected provider and is asked for again on every request")
    func languageAskedOnEveryRequest() {
        let languageCodes = SequencedLanguageCodes(["pt", "pl"])
        let factory = makeFactory(resultLimit: 10, languageCodes: languageCodes)
        #expect(languageCodes.callCount == 0)

        let first = factory.request(forName: "Lisbon")
        let second = factory.request(forName: "Lisbon")

        #expect(first.languageCode == "pt")
        #expect(second.languageCode == "pl")
        #expect(languageCodes.callCount == 2)
    }

    @Test("The provider's language code is sent exactly as provided", arguments: ["en", "pt", "zh", "PT", "pt-BR"])
    func languagePassesThrough(code: String) {
        let endpoint = makeFactory(resultLimit: 10, languageCodes: SequencedLanguageCodes([code])).request(forName: "Lisbon")
        #expect(endpoint.languageCode == code)
    }

    @Test(
        "The standard factory searches for ten results in the locale's language",
        arguments: [("en_US", "en"), ("pt_BR", "pt"), ("pl_PL", "pl"), ("", "en")]
    )
    func standardFactory(localeIdentifier: String, expected: String) {
        let endpoint = Fixtures.geocodingRequests(localeIdentifier: localeIdentifier).request(forName: "São Paulo")
        #expect(endpoint.name == "São Paulo")
        #expect(endpoint.resultLimit == OpenMeteoStandard.geocodingResultLimit)
        #expect(endpoint.languageCode == expected)
    }

    @Test("The standard factory builds the Portuguese São Paulo search URL")
    func standardFactoryURL() throws {
        let endpoint = Fixtures.geocodingRequests(localeIdentifier: "pt_BR").request(forName: "São Paulo")
        let request = try Fixtures.requestBuilder(host: OpenMeteoStandard.geocodingHost).makeRequest(for: endpoint)
        #expect(request.url?.absoluteString == "https://geocoding-api.open-meteo.com/v1/search?name=S%C3%A3o%20Paulo&count=10&language=pt&format=json")
    }

    private func makeFactory(resultLimit: Int, languageCodes: any LanguageCodeProviding) -> GeocodingRequestFactory {
        GeocodingRequestFactory(
            resultLimit: resultLimit,
            allowedResultLimits: OpenMeteoStandard.geocodingResultLimits,
            languageCodes: languageCodes
        )
    }
}
