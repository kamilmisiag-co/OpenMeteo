//
//  CitySearching.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public protocol CitySearching: Sendable {
    func search(_ rawQuery: String) async throws -> CitySearchResult
}
