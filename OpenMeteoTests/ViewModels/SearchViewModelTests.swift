//
//  SearchViewModelTests.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic
import Testing
@testable import OpenMeteo

@Suite("Search view model")
@MainActor
struct SearchViewModelTests {
    private typealias Request = SearchResolverDouble.Request

    nonisolated private static func found(_ request: Request) -> CitySearchState? {
        .results(query: trimmed(request.query), cities: [PreviewCities.lisbon])
    }

    nonisolated private static func trimmed(_ query: String) -> String {
        query.trimmingCharacters(in: .whitespaces)
    }

    nonisolated private static func immediate(_ rawQuery: String, current: CitySearchState) -> CitySearchState? {
        let query = trimmed(rawQuery)
        guard query.count >= 2 else { return current == .idle ? nil : .idle }
        guard query != current.shownQuery else { return nil }
        return .searching(query: query, previous: current.shownCities)
    }

    private func makeViewModel(
        recents: ScriptedRecentCitiesManager = ScriptedRecentCitiesManager(),
        sleeper: ControlledSleeper = ControlledSleeper(),
        resolution: @escaping @Sendable (Request) async -> CitySearchState? = { Self.found($0) }
    ) -> (SearchViewModel, SearchResolverDouble) {
        let resolver = SearchResolverDouble(immediate: { Self.immediate($0, current: $1) }, resolution: resolution)
        let dependencies = ViewModelFixtures.searchDependencies(resolver: resolver, recents: recents, sleeper: sleeper)
        return (SearchViewModel(dependencies: dependencies), resolver)
    }

    private func type(_ query: String, into viewModel: SearchViewModel) {
        viewModel.query = query
        viewModel.queryDidChange()
    }

    @Test("Starts idle with the recents the manager has")
    func initialState() {
        let recents = ScriptedRecentCitiesManager(cities: [PreviewCities.lisbon, PreviewCities.bergen])
        let (viewModel, resolver) = makeViewModel(recents: recents)

        #expect(viewModel.state == .idle)
        #expect(viewModel.recents == [PreviewCities.lisbon, PreviewCities.bergen])
        #expect(recents.calls == [.recentCities])
        #expect(!viewModel.isShowingProgress)
        #expect(resolver.requests.isEmpty)
    }

    @Test("Typing shows the resolver's immediate state at once")
    func immediateState() {
        let (viewModel, resolver) = makeViewModel()

        type("Lis", into: viewModel)

        #expect(viewModel.state == .searching(query: "Lis", previous: []))
        #expect(resolver.requests.isEmpty)
    }

    @Test("Typing keeps the state when the resolver has nothing immediate")
    func noImmediateState() {
        let (viewModel, _) = makeViewModel()

        type("L", into: viewModel)

        #expect(viewModel.state == .idle)
    }

    @Test("A search with nothing pending sends no request")
    func nothingPending() async {
        let (viewModel, resolver) = makeViewModel()

        await viewModel.search()
        type("Lis", into: viewModel)
        await viewModel.search()
        type("Lis ", into: viewModel)
        await viewModel.search()

        #expect(resolver.requests == [Request(query: "Lis", debounced: true)])
        #expect(viewModel.state == .results(query: "Lis", cities: [PreviewCities.lisbon]))
    }

    @Test("A search that finds an unreported query change hands it to a new request instead of resolving it")
    func searchWithoutQueryChange() async {
        let (viewModel, resolver) = makeViewModel()
        viewModel.query = "Lis"

        await viewModel.search()

        #expect(resolver.requests.isEmpty)
        #expect(viewModel.state == .searching(query: "Lis", previous: []))
        #expect(viewModel.request == SearchRequest(id: 1, isDebounced: true))

        await viewModel.search()

        #expect(resolver.requests == [Request(query: "Lis", debounced: true)])
        #expect(viewModel.state == .results(query: "Lis", cities: [PreviewCities.lisbon]))
    }

    @Test("A cancelled search drops its result even when the resolver returns one")
    func cancelledSearch() async {
        let gate = AsyncGate()
        let (viewModel, resolver) = makeViewModel { request in
            await gate.wait()
            return Self.found(request)
        }
        type("Lis", into: viewModel)

        let search = Task { await viewModel.search() }
        #expect(await Polling.until { resolver.requests.count == 1 })
        search.cancel()
        await gate.open()
        await search.value

        #expect(viewModel.state == .searching(query: "Lis", previous: []))
    }

    @Test("Try again resolves without the debounce")
    func retryIsNotDebounced() async {
        let (viewModel, resolver) = makeViewModel { request in
            request.debounced ? .failed(query: "Lis", failure: .offline) : Self.found(request)
        }
        type("Lis", into: viewModel)
        await viewModel.search()
        #expect(viewModel.state == .failed(query: "Lis", failure: .offline))

        viewModel.retry()
        await viewModel.search()

        #expect(resolver.requests == [Request(query: "Lis", debounced: true), Request(query: "Lis", debounced: false)])
        #expect(viewModel.state == .results(query: "Lis", cities: [PreviewCities.lisbon]))
    }

    @Test("Try again shows the searching state at once and starts an undebounced request")
    func retryShowsSearching() async {
        let gate = AsyncGate()
        let (viewModel, resolver) = makeViewModel { request in
            guard !request.debounced else { return .failed(query: "Lis", failure: .unavailable) }
            await gate.wait()
            return Self.found(request)
        }
        type("Lis", into: viewModel)
        await viewModel.search()
        let failedRequest = viewModel.request

        viewModel.retry()

        #expect(viewModel.state == .searching(query: "Lis", previous: []))
        #expect(viewModel.request.id == failedRequest.id + 1)
        #expect(!viewModel.request.isDebounced)
        let search = Task { await viewModel.search() }
        #expect(await Polling.until { resolver.requests.count == 2 })
        await gate.open()
        await search.value

        #expect(viewModel.state == .results(query: "Lis", cities: [PreviewCities.lisbon]))
    }

    @Test("Try again does nothing unless the search failed")
    func retryIgnoredWithoutFailure() async {
        let (viewModel, resolver) = makeViewModel()
        type("Lis", into: viewModel)
        await viewModel.search()
        let shownRequest = viewModel.request

        viewModel.retry()

        #expect(viewModel.request == shownRequest)
        #expect(viewModel.state == .results(query: "Lis", cities: [PreviewCities.lisbon]))
        #expect(resolver.requests.count == 1)
    }

    @Test("A retry that finishes after the query changed is dropped")
    func staleRetryDropped() async {
        let gate = AsyncGate()
        let (viewModel, resolver) = makeViewModel { request in
            guard !request.debounced else { return .failed(query: "Lis", failure: .offline) }
            await gate.wait()
            return Self.found(request)
        }
        type("Lis", into: viewModel)
        await viewModel.search()

        viewModel.retry()
        let retry = Task { await viewModel.search() }
        #expect(await Polling.until { resolver.requests.count == 2 })
        type("Lisb", into: viewModel)
        await gate.open()
        await retry.value

        #expect(viewModel.state == .searching(query: "Lisb", previous: []))
    }

    @Test("A typed search waits out the debounce before the progress delay starts")
    func progressAfterDelay() async {
        let gate = AsyncGate()
        let sleeper = ControlledSleeper()
        let (viewModel, resolver) = makeViewModel(sleeper: sleeper) { request in
            await gate.wait()
            return Self.found(request)
        }
        type("Lis", into: viewModel)

        let search = Task { await viewModel.search() }
        #expect(await Polling.until { sleeper.pendingCount == 1 && resolver.requests.count == 1 })
        #expect(!viewModel.isShowingProgress)
        #expect(sleeper.durations == [ViewModelFixtures.debounce + ViewModelFixtures.progressDelay])

        sleeper.wakeAll()
        #expect(await Polling.until { viewModel.isShowingProgress })

        await gate.open()
        await search.value
        #expect(!viewModel.isShowingProgress)
        #expect(viewModel.state == .results(query: "Lis", cities: [PreviewCities.lisbon]))
    }

    @Test("Progress never appears when results arrive before the delay")
    func noProgressForFastResults() async {
        let sleeper = ControlledSleeper()
        let (viewModel, _) = makeViewModel(sleeper: sleeper)
        type("Lis", into: viewModel)

        await viewModel.search()

        #expect(!viewModel.isShowingProgress)
        #expect(sleeper.pendingCount == 0)
    }

    @Test("Progress stops waiting when the search is cancelled")
    func progressCancelledWithSearch() async {
        let gate = AsyncGate()
        let sleeper = ControlledSleeper()
        let (viewModel, resolver) = makeViewModel(sleeper: sleeper) { request in
            await gate.wait()
            return Self.found(request)
        }
        type("Lis", into: viewModel)

        let search = Task { await viewModel.search() }
        #expect(await Polling.until { sleeper.pendingCount == 1 && resolver.requests.count == 1 })
        search.cancel()

        #expect(await Polling.until { sleeper.pendingCount == 0 })
        #expect(!viewModel.isShowingProgress)
        await gate.open()
        await search.value
    }

    @Test("Progress hides when the query is cleared")
    func progressHiddenWhenCleared() async {
        let gate = AsyncGate()
        let sleeper = ControlledSleeper()
        let (viewModel, _) = makeViewModel(sleeper: sleeper) { request in
            await gate.wait()
            return Self.found(request)
        }
        type("Lis", into: viewModel)
        let search = Task { await viewModel.search() }
        #expect(await Polling.until { sleeper.pendingCount == 1 })
        sleeper.wakeAll()
        #expect(await Polling.until { viewModel.isShowingProgress })

        type("", into: viewModel)

        #expect(viewModel.state == .idle)
        #expect(!viewModel.isShowingProgress)
        search.cancel()
        await gate.open()
        await search.value
    }

    @Test("Try again starts the progress delay without the debounce")
    func retryProgressDelay() async {
        let gate = AsyncGate()
        let sleeper = ControlledSleeper()
        let (viewModel, resolver) = makeViewModel(sleeper: sleeper) { request in
            guard !request.debounced else { return .failed(query: "Lis", failure: .offline) }
            await gate.wait()
            return Self.found(request)
        }
        type("Lis", into: viewModel)
        await viewModel.search()

        viewModel.retry()
        let retry = Task { await viewModel.search() }
        #expect(await Polling.until { sleeper.pendingCount == 1 && resolver.requests.count == 2 })
        #expect(sleeper.durations.last == ViewModelFixtures.progressDelay)
        await gate.open()
        await retry.value
    }

    @Test("Only a change of the searched query starts a new request")
    func requestFollowsSearchedQuery() {
        let (viewModel, _) = makeViewModel()
        #expect(viewModel.request == SearchRequest(id: 0, isDebounced: true))

        type("Lis", into: viewModel)
        #expect(viewModel.request == SearchRequest(id: 1, isDebounced: true))

        type("Lis ", into: viewModel)
        #expect(viewModel.request.id == 1)

        type("Lisb", into: viewModel)
        #expect(viewModel.request.id == 2)

        type("L", into: viewModel)
        #expect(viewModel.state == .idle)
        #expect(viewModel.request.id == 3)

        type("", into: viewModel)
        #expect(viewModel.request.id == 3)
    }

    @Test("Results keep the request, so the finished search is not started again")
    func resultsKeepRequest() async {
        let (viewModel, resolver) = makeViewModel()
        type("Lis", into: viewModel)
        await viewModel.search()

        type("Lis ", into: viewModel)
        await viewModel.search()

        #expect(viewModel.request.id == 1)
        #expect(resolver.requests.count == 1)
    }

    @Test("An edit that keeps the failed query searches again")
    func editAfterFailureSearchesAgain() async {
        let (viewModel, resolver) = makeViewModel { _ in .failed(query: "Lis", failure: .offline) }
        type("Lis", into: viewModel)
        await viewModel.search()
        #expect(viewModel.state == .failed(query: "Lis", failure: .offline))

        type("Lis ", into: viewModel)

        #expect(viewModel.state == .searching(query: "Lis", previous: []))
        #expect(viewModel.request == SearchRequest(id: 2, isDebounced: true))
        await viewModel.search()
        #expect(resolver.requests == [Request(query: "Lis", debounced: true), Request(query: "Lis ", debounced: true)])
    }

    @Test("A search does not show progress once the query it awaits has been replaced")
    func progressOnlyForAwaitedQuery() async {
        let gate = AsyncGate()
        let sleeper = ControlledSleeper()
        let (viewModel, resolver) = makeViewModel(sleeper: sleeper) { request in
            await gate.wait()
            return Self.found(request)
        }
        type("Lis", into: viewModel)
        let search = Task { await viewModel.search() }
        #expect(await Polling.until { sleeper.pendingCount == 1 && resolver.requests.count == 1 })

        type("Lisb", into: viewModel)
        sleeper.wakeAll()
        await gate.open()
        await search.value

        #expect(!viewModel.isShowingProgress)
        #expect(viewModel.state == .searching(query: "Lisb", previous: []))
    }

    @Test("Opening a city records the visit and shows the recents the manager returns")
    func openRecordsVisit() {
        let recents = ScriptedRecentCitiesManager(cities: [PreviewCities.lisbon], afterVisit: [PreviewCities.bergen, PreviewCities.lisbon])
        let (viewModel, _) = makeViewModel(recents: recents)

        viewModel.open(PreviewCities.bergen)

        #expect(recents.calls == [.recentCities, .recordVisit(PreviewCities.bergen)])
        #expect(viewModel.recents == [PreviewCities.bergen, PreviewCities.lisbon])
    }

    @Test("Removing recents asks the manager to remove the cities at the positions that exist")
    func removeRecents() {
        let recents = ScriptedRecentCitiesManager(cities: [PreviewCities.lisbon, PreviewCities.bergen, PreviewCities.zakopane], afterRemoval: [PreviewCities.bergen])
        let (viewModel, _) = makeViewModel(recents: recents)

        viewModel.removeRecents(at: IndexSet([0, 2, 5]))

        #expect(recents.calls == [.recentCities, .remove([PreviewCities.lisbon.id, PreviewCities.zakopane.id])])
        #expect(viewModel.recents == [PreviewCities.bergen])
    }

    @Test("Removing recents at positions that do not exist asks the manager nothing")
    func removeMissingRecents() {
        let recents = ScriptedRecentCitiesManager(cities: [PreviewCities.lisbon, PreviewCities.bergen])
        let (viewModel, _) = makeViewModel(recents: recents)

        viewModel.removeRecents(at: IndexSet(integer: 2))

        #expect(recents.calls == [.recentCities])
        #expect(viewModel.recents == [PreviewCities.lisbon, PreviewCities.bergen])
    }

    @Test("Clearing recents asks the manager to remove them all and empties the list")
    func clearRecents() {
        let recents = ScriptedRecentCitiesManager(cities: [PreviewCities.lisbon, PreviewCities.bergen])
        let (viewModel, _) = makeViewModel(recents: recents)

        viewModel.clearRecents()

        #expect(recents.calls == [.recentCities, .removeAll])
        #expect(viewModel.recents.isEmpty)
    }

    @Test("Recents that come back unchanged do not notify observers")
    func unchangedRecents() {
        let recents = ScriptedRecentCitiesManager(cities: [PreviewCities.lisbon], afterVisit: [PreviewCities.lisbon], afterRemoval: [])
        let (viewModel, _) = makeViewModel(recents: recents)
        let probe = ObservationProbe()
        probe.track { _ = viewModel.recents }

        viewModel.open(PreviewCities.lisbon)
        #expect(probe.changeCount == 0)

        viewModel.removeRecents(at: IndexSet(integer: 0))
        #expect(probe.changeCount == 1)
        #expect(viewModel.recents.isEmpty)
    }
}
