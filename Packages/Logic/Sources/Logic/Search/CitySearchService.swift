//
//  CitySearchService.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Utils

public protocol CitySearching: Sendable {
    func search(_ rawQuery: String) async throws -> CitySearchResult
}

public struct CitySearchService: CitySearching {
    private let geocoder: any CityGeocoding
    private let normalizer: any SearchQueryNormalizing

    public init(geocoder: any CityGeocoding, normalizer: any SearchQueryNormalizing) {
        self.geocoder = geocoder
        self.normalizer = normalizer
    }

    public func search(_ rawQuery: String) async throws -> CitySearchResult {
        guard let query = normalizer.normalizedQuery(from: rawQuery) else { return .queryTooShort }
        let cities = try await geocoder.cities(named: query)
        try Task.checkCancellation()
        let matches = cities.uniqued(by: \.id)
        return matches.isEmpty ? .noMatches(query: query) : .matches(query: query, cities: matches)
    }
}
