//
//  ForecastLoaderTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Logic
import LogicMocks
import Synchronization
import Testing

@Suite("Forecast loader")
struct ForecastLoaderTests {
    private enum LoadError: Error, Hashable {
        case broken
    }

    private final class RecordingFailureClassifier: FailureClassifying {
        private let classified: ServiceFailure
        private let received = Mutex<[any Error]>([])

        init(classifying classified: ServiceFailure) {
            self.classified = classified
        }

        var receivedErrors: [any Error] {
            received.withLock { $0 }
        }

        func failure(for error: any Error) -> ServiceFailure {
            received.withLock { $0.append(error) }
            return classified
        }
    }

    private static let live = result(for: Fixtures.lisbon, origin: .live)
    private static let cached = result(for: Fixtures.lisbon, origin: .cache)
    private static let bergen = result(for: Fixtures.bergen, origin: .live)

    @Test("The provider is asked for the requested city and its forecast is the loaded outcome")
    func loadedOutcome() async {
        let forecasts = MockForecastProvider { city in city == Fixtures.bergen ? Self.bergen : Self.cached }
        let failures = RecordingFailureClassifier(classifying: .unavailable)
        let loader = ForecastLoader(forecasts: forecasts, failures: failures)

        #expect(await loader.load(Fixtures.lisbon) == .loaded(Self.cached))
        #expect(await loader.load(Fixtures.bergen) == .loaded(Self.bergen))
        #expect(await forecasts.requestedCities == [Fixtures.lisbon, Fixtures.bergen])
        #expect(failures.receivedErrors.isEmpty)
    }

    @Test("A failed load reports the injected classifier's failure for the provider's error", arguments: [
        ServiceFailure.offline, .noUpcomingDays, .unavailable,
    ])
    func failedOutcome(failure: ServiceFailure) async {
        let forecasts = MockForecastProvider { _ in throw LoadError.broken }
        let failures = RecordingFailureClassifier(classifying: failure)
        let loader = ForecastLoader(forecasts: forecasts, failures: failures)

        #expect(await loader.load(Fixtures.lisbon) == .failed(failure))
        #expect(await forecasts.requestedCities == [Fixtures.lisbon])
        #expect(failures.receivedErrors.map { $0 as? LoadError } == [.broken])
    }

    @Test("A cancellation error from a load that was not cancelled goes to the classifier like any other error")
    func cancellationErrorWithoutCancellation() async {
        let forecasts = MockForecastProvider { _ in throw CancellationError() }
        let failures = RecordingFailureClassifier(classifying: .offline)
        let loader = ForecastLoader(forecasts: forecasts, failures: failures)

        #expect(await loader.load(Fixtures.lisbon) == .failed(.offline))
        #expect(failures.receivedErrors.count == 1)
        #expect(failures.receivedErrors.allSatisfy { $0 is CancellationError })
    }

    @Test("A forecast that arrives after the load was cancelled gives no outcome")
    func cancelledAfterSuccess() async {
        let forecasts = MockForecastProvider { _ in
            withUnsafeCurrentTask { $0?.cancel() }
            return Self.live
        }
        let failures = RecordingFailureClassifier(classifying: .unavailable)
        let loader = ForecastLoader(forecasts: forecasts, failures: failures)

        let outcome = await Task { await loader.load(Fixtures.lisbon) }.value

        #expect(outcome == nil)
        #expect(await forecasts.requestedCities == [Fixtures.lisbon])
        #expect(failures.receivedErrors.isEmpty)
    }

    @Test("A failure that arrives after the load was cancelled gives no outcome and never reaches the classifier")
    func cancelledAfterFailure() async {
        let forecasts = MockForecastProvider { _ in
            withUnsafeCurrentTask { $0?.cancel() }
            throw LoadError.broken
        }
        let failures = RecordingFailureClassifier(classifying: .offline)
        let loader = ForecastLoader(forecasts: forecasts, failures: failures)

        let outcome = await Task { await loader.load(Fixtures.lisbon) }.value

        #expect(outcome == nil)
        #expect(await forecasts.requestedCities == [Fixtures.lisbon])
        #expect(failures.receivedErrors.isEmpty)
    }

    @Test("With the standard classifier a load gives the forecast or the kind of failure")
    func standardClassifier() async {
        let cases: [(any Error, ServiceFailure)] = [
            (URLError(.notConnectedToInternet), .offline),
            (URLError(.timedOut), .offline),
            (ForecastError.noUpcomingDays, .noUpcomingDays),
            (URLError(.badServerResponse), .unavailable),
            (LoadError.broken, .unavailable),
            (CancellationError(), .unavailable),
            (URLError(.cancelled), .unavailable),
        ]

        #expect(await standardLoader(MockForecastProvider { _ in Self.live }).load(Fixtures.lisbon) == .loaded(Self.live))
        for (error, failure) in cases {
            #expect(await standardLoader(MockForecastProvider { _ in throw error }).load(Fixtures.lisbon) == .failed(failure))
        }
    }

    @Test("With the standard classifier a cancelled load gives no outcome, whatever the provider ends with")
    func standardCancellation() async {
        let succeeding = standardLoader(MockForecastProvider { _ in
            withUnsafeCurrentTask { $0?.cancel() }
            return Self.live
        })
        let failing = standardLoader(MockForecastProvider { _ in
            withUnsafeCurrentTask { $0?.cancel() }
            throw URLError(.notConnectedToInternet)
        })
        let cancelling = standardLoader(MockForecastProvider { _ in
            withUnsafeCurrentTask { $0?.cancel() }
            throw CancellationError()
        })

        #expect(await Task { await succeeding.load(Fixtures.lisbon) }.value == nil)
        #expect(await Task { await failing.load(Fixtures.lisbon) }.value == nil)
        #expect(await Task { await cancelling.load(Fixtures.lisbon) }.value == nil)
    }

    private static func result(for city: City, origin: ForecastResult.Origin) -> ForecastResult {
        let days = Fixtures.week(startingOn: Fixtures.referenceNow, in: city.timeZoneIdentifier ?? "UTC")
        return ForecastResult(forecast: CityForecast(city: city, days: days, outlooks: [], fetchedAt: Fixtures.referenceNow), origin: origin)
    }

    private func standardLoader(_ forecasts: MockForecastProvider) -> ForecastLoader {
        ForecastLoader(forecasts: forecasts, failures: ErrorFailureClassifier())
    }
}
