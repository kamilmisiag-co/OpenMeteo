//
//  ErrorFailureClassifierTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Logic
import Testing
import UtilsMocks

@Suite("Error failure classifier")
struct ErrorFailureClassifierTests {
    private let classifier = ErrorFailureClassifier()

    @Test("Cancellation errors are reported as the service being unavailable, since callers decide cancellation from their task")
    func cancellation() {
        #expect(classifier.failure(for: CancellationError()) == .unavailable)
        #expect(classifier.failure(for: URLError(.cancelled)) == .unavailable)
        #expect(classifier.failure(for: WrappedError(underlyingError: CancellationError())) == .unavailable)
        #expect(classifier.failure(for: WrappedError(underlyingError: WrappedError(underlyingError: CancellationError()))) == .unavailable)
        #expect(classifier.failure(for: WrappedError(underlyingError: URLError(.cancelled))) == .unavailable)
    }

    @Test("A forecast without upcoming days is reported as having no upcoming days")
    func noUpcomingDays() {
        #expect(classifier.failure(for: ForecastError.noUpcomingDays) == .noUpcomingDays)
    }

    @Test("Connectivity failures are reported as offline", arguments: [URLError.Code.notConnectedToInternet])
    func connectivity(code: URLError.Code) {
        #expect(classifier.failure(for: URLError(code)) == .offline)
    }

    @Test("Other URL errors are reported as the service being unavailable", arguments: [URLError.Code.badServerResponse])
    func otherURLErrors(code: URLError.Code) {
        #expect(classifier.failure(for: URLError(code)) == .unavailable)
    }

    @Test("Errors unrelated to connectivity or the forecast are reported as the service being unavailable")
    func unrelatedErrors() {
        #expect(classifier.failure(for: UnrelatedError.failed) == .unavailable)
        #expect(classifier.failure(for: WrappedError(underlyingError: nil)) == .unavailable)
        #expect(classifier.failure(for: WrappedError(underlyingError: UnrelatedError.failed)) == .unavailable)
    }
}
