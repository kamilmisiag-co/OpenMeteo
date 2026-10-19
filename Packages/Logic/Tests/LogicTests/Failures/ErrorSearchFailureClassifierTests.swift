//
//  ErrorSearchFailureClassifierTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Logic
import Testing
import UtilsMocks

@Suite("Error search failure classifier")
struct ErrorSearchFailureClassifierTests {
    private let classifier = ErrorSearchFailureClassifier()

    @Test("Connectivity failures make the search offline", arguments: [URLError.Code.notConnectedToInternet])
    func connectivity(code: URLError.Code) {
        #expect(classifier.failure(for: URLError(code)) == .offline)
    }

    @Test("Cancellation errors make the search unavailable, since the flow decides cancellation from its task")
    func cancellation() {
        #expect(classifier.failure(for: CancellationError()) == .unavailable)
        #expect(classifier.failure(for: URLError(.cancelled)) == .unavailable)
        #expect(classifier.failure(for: WrappedError(underlyingError: CancellationError())) == .unavailable)
        #expect(classifier.failure(for: WrappedError(underlyingError: URLError(.cancelled))) == .unavailable)
    }

    @Test("Other URL errors make the search unavailable", arguments: [URLError.Code.badServerResponse])
    func otherURLErrors(code: URLError.Code) {
        #expect(classifier.failure(for: URLError(code)) == .unavailable)
    }

    @Test("Errors unrelated to connectivity, including a forecast without upcoming days, make the search unavailable")
    func unrelatedErrors() {
        #expect(classifier.failure(for: UnrelatedError.failed) == .unavailable)
        #expect(classifier.failure(for: ForecastError.noUpcomingDays) == .unavailable)
        #expect(classifier.failure(for: WrappedError(underlyingError: nil)) == .unavailable)
        #expect(classifier.failure(for: WrappedError(underlyingError: UnrelatedError.failed)) == .unavailable)
    }
}
