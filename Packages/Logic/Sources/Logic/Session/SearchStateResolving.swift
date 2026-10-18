//
//  SearchStateResolving.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public protocol SearchStateResolving: Sendable {
    func immediateState(for rawQuery: String, current: CitySearchState) -> CitySearchState?
    func resolvedState(for rawQuery: String, debounced: Bool) async -> CitySearchState?
}
