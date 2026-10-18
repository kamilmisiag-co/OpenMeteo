//
//  CitySearchState.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public enum CitySearchState: Hashable, Sendable {
    case idle
    case searching(query: String, previous: [City])
    case results(query: String, cities: [City])
    case noResults(query: String)
    case failed(query: String, failure: SearchFailure)

    public var shownQuery: String? {
        switch self {
        case .results(let query, _), .noResults(let query): query
        case .idle, .searching, .failed: nil
        }
    }

    public var shownCities: [City] {
        switch self {
        case .results(_, let cities): cities
        case .searching(_, let previous): previous
        case .idle, .noResults, .failed: []
        }
    }
}
