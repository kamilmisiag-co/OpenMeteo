//
//  CitySearchFlow.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public struct CitySearchFlow: SearchStateResolving {
    private let search: any CitySearching
    private let normalizer: any SearchQueryNormalizing
    private let delayer: any Delaying
    private let debounce: Duration
    private let failures: any SearchFailureClassifying

    public init(
        search: any CitySearching,
        normalizer: any SearchQueryNormalizing,
        delayer: any Delaying,
        debounce: Duration,
        failures: any SearchFailureClassifying
    ) {
        self.search = search
        self.normalizer = normalizer
        self.delayer = delayer
        self.debounce = debounce
        self.failures = failures
    }

    public func immediateState(for rawQuery: String, current: CitySearchState) -> CitySearchState? {
        guard let query = normalizer.normalizedQuery(from: rawQuery) else { return current == .idle ? nil : .idle }
        guard query != current.shownQuery else { return nil }
        return .searching(query: query, previous: current.shownCities)
    }

    public func resolvedState(for rawQuery: String, debounced: Bool) async -> CitySearchState? {
        guard let query = normalizer.normalizedQuery(from: rawQuery) else { return Task.isCancelled ? nil : .idle }
        if debounced {
            try? await delayer.delay(for: debounce)
        }
        guard !Task.isCancelled else { return nil }
        do {
            let result = try await search.search(rawQuery)
            guard !Task.isCancelled else { return nil }
            return state(for: result)
        } catch {
            return Task.isCancelled ? nil : .failed(query: query, failure: failures.failure(for: error))
        }
    }

    private func state(for result: CitySearchResult) -> CitySearchState {
        switch result {
        case .queryTooShort: .idle
        case .noMatches(let query): .noResults(query: query)
        case .matches(let query, let cities): .results(query: query, cities: cities)
        }
    }
}
