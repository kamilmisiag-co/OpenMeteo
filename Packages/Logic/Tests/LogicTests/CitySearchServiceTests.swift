//
//  CitySearchServiceTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Logic
import LogicMocks
import Testing

@Suite("City search service")
struct CitySearchServiceTests {
    private enum GeocoderError: Error {
        case unavailable
    }

    private struct StubNormalizer: SearchQueryNormalizing {
        let normalize: @Sendable (String) -> String?

        func normalizedQuery(from rawQuery: String) -> String? {
            normalize(rawQuery)
        }
    }

    private func service(using geocoder: MockCityGeocoder) -> CitySearchService {
        CitySearchService(geocoder: geocoder, normalizer: CitySearchQueryNormalizer(minimumLength: 2, separators: [","]))
    }

    @Test("Matching cities are returned with the normalized query that was sent to the geocoder")
    func matches() async throws {
        let geocoder = MockCityGeocoder { _ in [Fixtures.lisbon, Fixtures.bergen] }
        let result = try await service(using: geocoder).search("  Lisbon ,  Portugal ")
        #expect(result == .matches(query: "Lisbon", cities: [Fixtures.lisbon, Fixtures.bergen]))
        #expect(await geocoder.requestedNames == ["Lisbon"])
    }

    @Test("An empty geocoder response means no matches for the normalized query")
    func noMatches() async throws {
        let geocoder = MockCityGeocoder { _ in [] }
        #expect(try await service(using: geocoder).search("Atlantis ,  Ocean") == .noMatches(query: "Atlantis"))
        #expect(await geocoder.requestedNames == ["Atlantis"])
    }

    @Test("Queries the normalizer rejects never reach the geocoder", arguments: ["", "   ", "\n", "L", ", Lisbon", " L , isbon"])
    func tooShort(raw: String) async throws {
        let geocoder = MockCityGeocoder { _ in [Fixtures.lisbon] }
        #expect(try await service(using: geocoder).search(raw) == .queryTooShort)
        #expect(await geocoder.requestedNames.isEmpty)
    }

    @Test("The injected normalizer decides whether and what is sent to the geocoder")
    func injectedNormalizer() async throws {
        let geocoder = MockCityGeocoder { _ in [Fixtures.zakopane] }
        let accepting = CitySearchService(geocoder: geocoder, normalizer: StubNormalizer { _ in "Zakopane" })
        let rejecting = CitySearchService(geocoder: geocoder, normalizer: StubNormalizer { _ in nil })
        #expect(try await accepting.search("z") == .matches(query: "Zakopane", cities: [Fixtures.zakopane]))
        #expect(try await rejecting.search("Zakopane, Poland") == .queryTooShort)
        #expect(await geocoder.requestedNames == ["Zakopane"])
    }

    @Test("Duplicate cities from the geocoder are removed, keeping the first of each")
    func deduplication() async throws {
        let geocoder = MockCityGeocoder { _ in [Fixtures.lisbon, Fixtures.bergen, Fixtures.lisboa, Fixtures.bergen, Fixtures.zakopane] }
        let result = try await service(using: geocoder).search("Lisbon")
        #expect(result == .matches(query: "Lisbon", cities: [Fixtures.lisbon, Fixtures.bergen, Fixtures.zakopane]))
    }

    @Test("Duplicates are matched by id, so a renamed copy of the first city is dropped")
    func deduplicationByID() async throws {
        let geocoder = MockCityGeocoder { _ in [Fixtures.lisboa, Fixtures.lisbon] }
        #expect(try await service(using: geocoder).search("Lisbon") == .matches(query: "Lisbon", cities: [Fixtures.lisboa]))
    }

    @Test("Geocoder errors propagate unchanged")
    func errorPropagation() async {
        let failing = MockCityGeocoder { _ in throw GeocoderError.unavailable }
        await #expect(throws: GeocoderError.unavailable) {
            try await service(using: failing).search("Lisbon")
        }
        let offline = MockCityGeocoder { _ in throw URLError(.notConnectedToInternet) }
        await #expect(throws: URLError(.notConnectedToInternet)) {
            try await service(using: offline).search("Lisbon")
        }
    }

    @Test("A search cancelled while the geocoder is working throws instead of returning stale results")
    func cancellation() async {
        let geocoder = MockCityGeocoder { _ in
            withUnsafeCurrentTask { $0?.cancel() }
            return [Fixtures.lisbon]
        }
        let searcher = service(using: geocoder)
        let task = Task { try await searcher.search("Lisbon") }
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(await geocoder.requestedNames == ["Lisbon"])
    }
}
