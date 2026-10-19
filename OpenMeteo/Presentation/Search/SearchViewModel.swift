//
//  SearchViewModel.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic
import Observation
import Utils

@Observable
final class SearchViewModel {
    struct Dependencies {
        let resolver: any SearchStateResolving
        let recents: any RecentCitiesManaging
        let sleeper: any Sleeping
        let debounce: Duration
        let progressDelay: Duration
    }

    var query = ""
    private(set) var state: CitySearchState = .idle
    private(set) var recents: [City] = []
    private(set) var isShowingProgress = false
    private(set) var request = SearchRequest(id: 0, isDebounced: true)

    @ObservationIgnored private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        recents = dependencies.recents.recentCities()
    }

    func queryDidChange() {
        apply(dependencies.resolver.immediateState(for: query, current: state), debounced: true)
    }

    func search() async {
        let started = request
        queryDidChange()
        guard request == started, let awaitedQuery = pendingQuery else { return }
        let resolved = await resolvedState(for: query, awaiting: awaitedQuery, debounced: request.isDebounced)
        guard !Task.isCancelled, let resolved, pendingQuery == awaitedQuery else { return }
        show(resolved)
    }

    func retry() {
        guard case .failed(let failedQuery, _) = state else { return }
        apply(.searching(query: failedQuery, previous: []), debounced: false)
    }

    func open(_ city: City) {
        showRecents(dependencies.recents.recordVisit(to: city))
    }

    func removeRecents(at offsets: IndexSet) {
        let cityIDs = Set(offsets.compactMap { recents.element(at: $0)?.id })
        guard !cityIDs.isEmpty else { return }
        showRecents(dependencies.recents.remove(cityIDs))
    }

    func clearRecents() {
        dependencies.recents.removeAll()
        showRecents([])
    }

    private var pendingQuery: String? {
        searchingQuery(in: state)
    }

    private func searchingQuery(in state: CitySearchState) -> String? {
        guard case .searching(let query, _) = state else { return nil }
        return query
    }

    private func apply(_ immediate: CitySearchState?, debounced: Bool) {
        guard let immediate else { return }
        let previous = state
        show(immediate)
        guard startsNewSearch(from: previous, to: immediate) else { return }
        request = SearchRequest(id: request.id + 1, isDebounced: debounced)
    }

    private func startsNewSearch(from previous: CitySearchState, to next: CitySearchState) -> Bool {
        switch next {
        case .searching(let query, _): searchingQuery(in: previous) != query
        case .idle: searchingQuery(in: previous) != nil
        case .results, .noResults, .failed: false
        }
    }

    private func resolvedState(for rawQuery: String, awaiting awaitedQuery: String, debounced: Bool) async -> CitySearchState? {
        await withTaskGroup(of: Void.self, returning: CitySearchState?.self) { group in
            let delay = debounced ? dependencies.debounce + dependencies.progressDelay : dependencies.progressDelay
            group.addTask { await self.revealProgress(after: delay, awaiting: awaitedQuery) }
            let resolved = await dependencies.resolver.resolvedState(for: rawQuery, debounced: debounced)
            group.cancelAll()
            return resolved
        }
    }

    private func revealProgress(after delay: Duration, awaiting awaitedQuery: String) async {
        guard (try? await dependencies.sleeper.sleep(for: delay)) != nil,
              !Task.isCancelled,
              pendingQuery == awaitedQuery,
              !isShowingProgress else { return }
        isShowingProgress = true
    }

    private func show(_ newState: CitySearchState) {
        if newState != state {
            state = newState
        }
        if pendingQuery == nil, isShowingProgress {
            isShowingProgress = false
        }
    }

    private func showRecents(_ cities: [City]) {
        guard cities != recents else { return }
        recents = cities
    }
}
