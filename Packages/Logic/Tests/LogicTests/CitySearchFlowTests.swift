//
//  CitySearchFlowTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Logic
import LogicMocks
import Synchronization
import Testing
import Utils
import UtilsMocks

@Suite("City search flow")
struct CitySearchFlowTests {
    private enum SearchError: Error {
        case unavailable
    }

    private enum SleepError: Error {
        case interrupted
    }

    private struct StubNormalizer: SearchQueryNormalizing {
        let normalize: @Sendable (String) -> String?

        func normalizedQuery(from rawQuery: String) -> String? {
            normalize(rawQuery)
        }
    }

    private final class RecordingFailureClassifier: SearchFailureClassifying {
        private let classified: SearchFailure
        private let received = Mutex<[any Error]>([])

        init(failure: SearchFailure) {
            classified = failure
        }

        var receivedErrors: [any Error] {
            received.withLock { $0 }
        }

        func failure(for error: any Error) -> SearchFailure {
            received.withLock { $0.append(error) }
            return classified
        }
    }

    private struct CancellingSleeper: Sleeping {
        func sleep(for duration: Duration) async throws {
            withUnsafeCurrentTask { $0?.cancel() }
        }
    }

    private final class FailingSleeper: Sleeping {
        private let error: any Error
        private let cancelling: Bool
        private let recorded = Mutex<[Duration]>([])

        init(throwing error: any Error, cancelling: Bool) {
            self.error = error
            self.cancelling = cancelling
        }

        var durations: [Duration] {
            recorded.withLock { $0 }
        }

        func sleep(for duration: Duration) async throws {
            recorded.withLock { $0.append(duration) }
            if cancelling {
                withUnsafeCurrentTask { $0?.cancel() }
            }
            throw error
        }
    }

    private static let debounce = Duration.milliseconds(40)
    private static let rawLisbon = "  Lisbon ,  Portugal "
    private static let lisbonResults = CitySearchState.results(query: "Lisbon", cities: [Fixtures.lisbon, Fixtures.lisboa])
    private let sleeper = RecordingSleeper()

    @Test("A query the normalizer rejects is idle at once and resolves to idle without debouncing or searching", arguments: [
        "", "   ", "L", ", Lisbon",
    ])
    func rejectedQuery(raw: String) async {
        let searcher = MockCitySearcher { _ in .matches(query: "Lisbon", cities: [Fixtures.lisbon]) }
        let resolver = flow(searching: searcher)
        #expect(resolver.immediateState(for: raw, current: Self.lisbonResults) == .idle)
        #expect(await resolver.resolvedState(for: raw, debounced: true) == .idle)
        #expect(await resolver.resolvedState(for: raw, debounced: false) == .idle)
        #expect(sleeper.durations.isEmpty)
        #expect(await searcher.queries.isEmpty)
    }

    @Test("A query whose results or no-results are already shown needs no new state", arguments: [
        (rawLisbon, lisbonResults),
        ("Atlantis", CitySearchState.noResults(query: "Atlantis")),
    ])
    func unchangedQuery(raw: String, current: CitySearchState) {
        #expect(flow().immediateState(for: raw, current: current) == nil)
    }

    @Test("A different query keeps the cities already on screen visible while it is searched", arguments: [
        (lisbonResults, CitySearchState.searching(query: "Bergen", previous: [Fixtures.lisbon, Fixtures.lisboa])),
        (CitySearchState.noResults(query: "Atlantis"), CitySearchState.searching(query: "Bergen", previous: [])),
        (CitySearchState.searching(query: "Ber", previous: [Fixtures.bergen]), CitySearchState.searching(query: "Bergen", previous: [Fixtures.bergen])),
    ])
    func newQuery(current: CitySearchState, expected: CitySearchState) {
        #expect(flow().immediateState(for: " Bergen , Norway", current: current) == expected)
    }

    @Test("Idle and failed states never block a search for the same query", arguments: [
        (CitySearchState.idle, CitySearchState.searching(query: "Lisbon", previous: [])),
        (CitySearchState.failed(query: "Lisbon", failure: .offline), CitySearchState.searching(query: "Lisbon", previous: [])),
        (CitySearchState.failed(query: "Lisbon", failure: .unavailable), CitySearchState.searching(query: "Lisbon", previous: [])),
    ])
    func unshownStates(current: CitySearchState, expected: CitySearchState) {
        #expect(flow().immediateState(for: Self.rawLisbon, current: current) == expected)
    }

    @Test("A pending search for the same query starts again, since the search in flight was cancelled when the text changed", arguments: [
        (CitySearchState.searching(query: "Lisbon", previous: [Fixtures.lisbon]), [Fixtures.lisbon]),
        (CitySearchState.searching(query: "Lisbon", previous: []), [City]()),
    ])
    func pendingSearchRestarts(current: CitySearchState, shown: [City]) {
        #expect(flow().immediateState(for: Self.rawLisbon, current: current) == .searching(query: "Lisbon", previous: shown))
        #expect(flow().immediateState(for: "Lisbon", current: current) == .searching(query: "Lisbon", previous: shown))
        #expect(flow().immediateState(for: " Bergen , Norway", current: current) == .searching(query: "Bergen", previous: shown))
    }

    @Test("A query the normalizer rejects needs no new state while the search is already idle", arguments: [
        "", "   ", "L", ", Lisbon",
    ])
    func rejectedQueryWhileIdle(raw: String) {
        #expect(flow().immediateState(for: raw, current: .idle) == nil)
    }

    @Test("A query the normalizer rejects clears any other search state back to idle", arguments: [
        lisbonResults,
        CitySearchState.noResults(query: "Atlantis"),
        .searching(query: "Lisbon", previous: [Fixtures.lisbon]),
        .failed(query: "Lisbon", failure: .unavailable),
    ])
    func rejectedQueryClearsState(current: CitySearchState) {
        #expect(flow().immediateState(for: " ", current: current) == .idle)
    }

    @Test("A debounced search waits for the injected debounce once and only then searches the raw query")
    func debouncedSearch() async {
        let searcher = MockCitySearcher { [sleeper] _ in
            #expect(sleeper.durations == [Self.debounce])
            return .matches(query: "Lisbon", cities: [Fixtures.lisbon])
        }
        let state = await flow(searching: searcher).resolvedState(for: Self.rawLisbon, debounced: true)
        #expect(state == .results(query: "Lisbon", cities: [Fixtures.lisbon]))
        #expect(sleeper.durations == [Self.debounce])
        #expect(await searcher.queries == [Self.rawLisbon])
    }

    @Test("A search that isn't debounced runs straight away without waiting")
    func immediateSearch() async {
        let searcher = MockCitySearcher { _ in .matches(query: "Lisbon", cities: [Fixtures.lisbon]) }
        let state = await flow(searching: searcher).resolvedState(for: Self.rawLisbon, debounced: false)
        #expect(state == .results(query: "Lisbon", cities: [Fixtures.lisbon]))
        #expect(sleeper.durations.isEmpty)
        #expect(await searcher.queries == [Self.rawLisbon])
    }

    @Test("A query the normalizer rejects resolves to nothing once the search was cancelled", arguments: ["", "   ", "L", ", Lisbon"])
    func rejectedQueryAfterCancellation(raw: String) async {
        let searcher = MockCitySearcher { _ in .matches(query: "Lisbon", cities: [Fixtures.lisbon]) }
        let resolver = flow(searching: searcher)
        for debounced in [false, true] {
            let task = Task {
                withUnsafeCurrentTask { $0?.cancel() }
                return await resolver.resolvedState(for: raw, debounced: debounced)
            }
            #expect(await task.value == nil)
        }
        #expect(sleeper.durations.isEmpty)
        #expect(await searcher.queries.isEmpty)
    }

    @Test("A search cancelled while debouncing resolves to nothing and never reaches the searcher")
    func cancelledWhileDebouncing() async {
        let searcher = MockCitySearcher { _ in .matches(query: "Lisbon", cities: [Fixtures.lisbon]) }
        let resolver = flow(searching: searcher)
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return await resolver.resolvedState(for: Self.rawLisbon, debounced: true)
        }
        #expect(await task.value == nil)
        #expect(sleeper.durations == [Self.debounce])
        #expect(await searcher.queries.isEmpty)
    }

    @Test("A search cancelled during a debounce that finishes anyway resolves to nothing and never reaches the searcher")
    func cancelledDuringUninterruptedDebounce() async {
        let searcher = MockCitySearcher { _ in .matches(query: "Lisbon", cities: [Fixtures.lisbon]) }
        let failures = RecordingFailureClassifier(failure: .unavailable)
        let resolver = flow(searching: searcher, sleeper: CancellingSleeper(), failures: failures)
        #expect(await Task { await resolver.resolvedState(for: Self.rawLisbon, debounced: true) }.value == nil)
        #expect(await searcher.queries.isEmpty)
        #expect(failures.receivedErrors.isEmpty)
    }

    @Test("A debounce that fails with a plain error while the search is not cancelled still searches and resolves", arguments: [
        SleepError.interrupted as any Error, URLError(.timedOut), SearchError.unavailable,
    ])
    func failedDebounceStillSearches(error: any Error) async {
        let searcher = MockCitySearcher { _ in .matches(query: "Lisbon", cities: [Fixtures.lisbon]) }
        let failures = RecordingFailureClassifier(failure: .offline)
        let sleeper = FailingSleeper(throwing: error, cancelling: false)
        let state = await flow(searching: searcher, sleeper: sleeper, failures: failures).resolvedState(for: Self.rawLisbon, debounced: true)
        #expect(state == .results(query: "Lisbon", cities: [Fixtures.lisbon]))
        #expect(sleeper.durations == [Self.debounce])
        #expect(await searcher.queries == [Self.rawLisbon])
        #expect(failures.receivedErrors.isEmpty)
    }

    @Test("A debounce that throws a cancellation error while the search itself is not cancelled still searches and resolves", arguments: [
        CancellationError() as any Error, URLError(.cancelled),
    ])
    func cancellationErrorFromDebounceStillSearches(error: any Error) async {
        let searcher = MockCitySearcher { _ in .matches(query: "Lisbon", cities: [Fixtures.lisbon]) }
        let failures = RecordingFailureClassifier(failure: .offline)
        let sleeper = FailingSleeper(throwing: error, cancelling: false)
        let state = await flow(searching: searcher, sleeper: sleeper, failures: failures).resolvedState(for: Self.rawLisbon, debounced: true)
        #expect(state == .results(query: "Lisbon", cities: [Fixtures.lisbon]))
        #expect(sleeper.durations == [Self.debounce])
        #expect(await searcher.queries == [Self.rawLisbon])
        #expect(failures.receivedErrors.isEmpty)
    }

    @Test("A debounce that fails with a plain error after the search was cancelled resolves to nothing and never reaches the searcher")
    func failedDebounceAfterCancellation() async {
        let searcher = MockCitySearcher { _ in .matches(query: "Lisbon", cities: [Fixtures.lisbon]) }
        let failures = RecordingFailureClassifier(failure: .offline)
        let sleeper = FailingSleeper(throwing: SleepError.interrupted, cancelling: true)
        let resolver = flow(searching: searcher, sleeper: sleeper, failures: failures)
        #expect(await Task { await resolver.resolvedState(for: Self.rawLisbon, debounced: true) }.value == nil)
        #expect(sleeper.durations == [Self.debounce])
        #expect(await searcher.queries.isEmpty)
        #expect(failures.receivedErrors.isEmpty)
    }

    @Test("A search that returns after it was cancelled resolves to nothing", arguments: [
        CitySearchResult.queryTooShort,
        .noMatches(query: "Lisbon"),
        .matches(query: "Lisbon", cities: [Fixtures.lisbon]),
    ])
    func cancelledAfterSearchReturns(result: CitySearchResult) async {
        let searcher = MockCitySearcher { _ in
            withUnsafeCurrentTask { $0?.cancel() }
            return result
        }
        let resolver = flow(searching: searcher)
        for debounced in [false, true] {
            #expect(await Task { await resolver.resolvedState(for: Self.rawLisbon, debounced: debounced) }.value == nil)
        }
        #expect(await searcher.queries == [Self.rawLisbon, Self.rawLisbon])
    }

    @Test("A search that fails after it was cancelled resolves to nothing without consulting the classifier, whatever the error")
    func cancelledAfterSearchFails() async {
        let errors: [any Error] = [SearchError.unavailable, CancellationError(), URLError(.cancelled), URLError(.notConnectedToInternet)]
        for error in errors {
            let searcher = MockCitySearcher { _ in
                withUnsafeCurrentTask { $0?.cancel() }
                throw error
            }
            let classifier = RecordingFailureClassifier(failure: .offline)
            let resolver = flow(searching: searcher, failures: classifier)
            for debounced in [false, true] {
                #expect(await Task { await resolver.resolvedState(for: Self.rawLisbon, debounced: debounced) }.value == nil)
            }
            #expect(await searcher.queries == [Self.rawLisbon, Self.rawLisbon])
            #expect(classifier.receivedErrors.isEmpty)
        }
    }

    @Test("Each search result maps to the state that shows it", arguments: [
        (CitySearchResult.queryTooShort, CitySearchState.idle),
        (CitySearchResult.noMatches(query: "Lisbon"), CitySearchState.noResults(query: "Lisbon")),
        (CitySearchResult.matches(query: "Lisbon", cities: [Fixtures.lisbon, Fixtures.lisboa]), lisbonResults),
    ])
    func resultMapping(result: CitySearchResult, expected: CitySearchState) async {
        let searcher = MockCitySearcher { _ in result }
        #expect(await flow(searching: searcher).resolvedState(for: Self.rawLisbon, debounced: false) == expected)
        #expect(await searcher.queries == [Self.rawLisbon])
    }

    @Test("A failed search reports the injected classifier's failure for the normalized query, debounced or not", arguments: [
        SearchFailure.offline, .unavailable,
    ], [false, true])
    func classifiedFailure(classified: SearchFailure, debounced: Bool) async {
        let searcher = MockCitySearcher { _ in throw SearchError.unavailable }
        let classifier = RecordingFailureClassifier(failure: classified)
        let state = await flow(searching: searcher, failures: classifier).resolvedState(for: Self.rawLisbon, debounced: debounced)
        #expect(state == .failed(query: "Lisbon", failure: classified))
        #expect(classifier.receivedErrors.map { $0 as? SearchError } == [.unavailable])
        #expect(await searcher.queries == [Self.rawLisbon])
        #expect(sleeper.durations == (debounced ? [Self.debounce] : []))
    }

    @Test("A cancellation error from a search that was not cancelled is classified like any other failure")
    func cancellationErrorWithoutCancellation() async {
        let searcher = MockCitySearcher { _ in throw CancellationError() }
        let classifier = RecordingFailureClassifier(failure: .offline)
        let standard = flow(searching: searcher, failures: ErrorSearchFailureClassifier())

        #expect(await flow(searching: searcher, failures: classifier).resolvedState(for: Self.rawLisbon, debounced: true) == .failed(
            query: "Lisbon", failure: .offline
        ))
        #expect(classifier.receivedErrors.count == 1)
        #expect(classifier.receivedErrors.allSatisfy { $0 is CancellationError })
        #expect(await standard.resolvedState(for: Self.rawLisbon, debounced: false) == .failed(query: "Lisbon", failure: .unavailable))
        #expect(await searcher.queries == [Self.rawLisbon, Self.rawLisbon])
    }

    @Test("The injected normalizer decides which query is shown, compared and reported")
    func injectedNormalizer() async {
        let searcher = MockCitySearcher { _ in throw SearchError.unavailable }
        let accepting = flow(searching: searcher, normalizer: StubNormalizer { _ in "Zakopane" })
        #expect(accepting.immediateState(for: "z", current: .idle) == .searching(query: "Zakopane", previous: []))
        #expect(accepting.immediateState(for: "z", current: .noResults(query: "Zakopane")) == nil)
        #expect(accepting.immediateState(for: "z", current: .searching(query: "Zakopane", previous: [])) == .searching(query: "Zakopane", previous: []))
        #expect(await accepting.resolvedState(for: "z", debounced: true) == .failed(query: "Zakopane", failure: .unavailable))

        let rejecting = flow(searching: searcher, normalizer: StubNormalizer { _ in nil })
        #expect(rejecting.immediateState(for: "Zakopane", current: Self.lisbonResults) == .idle)
        #expect(rejecting.immediateState(for: "Zakopane", current: .idle) == nil)
        #expect(await rejecting.resolvedState(for: "Zakopane", debounced: true) == .idle)
        #expect(await searcher.queries == ["z"])
        #expect(sleeper.durations == [Self.debounce])
    }

    private func flow(
        searching searcher: MockCitySearcher = MockCitySearcher { _ in .queryTooShort },
        normalizer: any SearchQueryNormalizing = CitySearchQueryNormalizer(
            minimumLength: StandardRules.minimumQueryLength,
            separators: StandardRules.querySeparators,
            invisibleScalars: StandardRules.queryInvisibleScalars
        ),
        sleeper customSleeper: (any Sleeping)? = nil,
        failures: any SearchFailureClassifying = RecordingFailureClassifier(failure: .unavailable)
    ) -> CitySearchFlow {
        CitySearchFlow(search: searcher, normalizer: normalizer, sleeper: customSleeper ?? sleeper, debounce: Self.debounce, failures: failures)
    }
}
