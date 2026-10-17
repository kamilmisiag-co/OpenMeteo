//
//  CitySearchResult.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public enum CitySearchResult: Hashable, Sendable {
    case queryTooShort
    case noMatches(query: String)
    case matches(query: String, cities: [City])
}
