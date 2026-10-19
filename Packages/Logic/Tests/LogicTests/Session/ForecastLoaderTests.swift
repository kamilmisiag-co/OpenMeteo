//
//  ForecastLoaderTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic
import LogicMocks
import Testing

@Suite("Forecast loader")
struct ForecastLoaderTests {
    private enum LoadError: Error, Hashable {
        case broken
    }

    private static let lisbonWeek = LogicFixtures.forecast(days: LogicFixtures.days())
    private static let live = LogicFixtures.result(lisbonWeek, origin: .live)
    private static let cached = LogicFixtures.result(lisbonWeek, origin: .cache)
    private static let bergen = LogicFixtures.result(
        LogicFixtures.forecast(city: SampleCities.bergen, days: LogicFixtures.days(in: "Europe/Oslo")),
        origin: .live
    )

    @Test("The provider is asked for the requested city and its forecast is the loaded outcome")
    func loadedOutcome() async {
        let forecasts = MockForecastProvider { city in city == SampleCities.bergen ? Self.bergen : Self.cached }
        let failures = RecordingFailureClassifier(classifying: .unavailable)
        let loader = ForecastLoader(forecasts: forecasts, failures: failures)

        #expect(await loader.load(SampleCities.lisbon) == .loaded(Self.cached))
        #expect(await loader.load(SampleCities.bergen) == .loaded(Self.bergen))
        #expect(await forecasts.requestedCities == [SampleCities.lisbon, SampleCities.bergen])
        #expect(failures.receivedErrors.isEmpty)
    }

    @Test("A failed load reports the injected classifier's failure for the provider's error")
    func failedOutcome() async {
        let forecasts = MockForecastProvider { _ in throw LoadError.broken }
        let failures = RecordingFailureClassifier(classifying: .noUpcomingDays)
        let loader = ForecastLoader(forecasts: forecasts, failures: failures)

        #expect(await loader.load(SampleCities.lisbon) == .failed(.noUpcomingDays))
        #expect(await forecasts.requestedCities == [SampleCities.lisbon])
        #expect(failures.receivedErrors.map { $0 as? LoadError } == [.broken])
    }

    @Test("A cancellation error from a load that was not cancelled goes to the classifier like any other error")
    func cancellationErrorWithoutCancellation() async {
        let forecasts = MockForecastProvider { _ in throw CancellationError() }
        let failures = RecordingFailureClassifier(classifying: .offline)
        let loader = ForecastLoader(forecasts: forecasts, failures: failures)

        #expect(await loader.load(SampleCities.lisbon) == .failed(.offline))
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

        let outcome = await Task { await loader.load(SampleCities.lisbon) }.value

        #expect(outcome == nil)
        #expect(await forecasts.requestedCities == [SampleCities.lisbon])
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

        let outcome = await Task { await loader.load(SampleCities.lisbon) }.value

        #expect(outcome == nil)
        #expect(await forecasts.requestedCities == [SampleCities.lisbon])
        #expect(failures.receivedErrors.isEmpty)
    }
}
