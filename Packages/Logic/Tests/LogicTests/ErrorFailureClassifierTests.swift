//
//  ErrorFailureClassifierTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Logic
import Testing
import Utils

@Suite("Error failure classifier")
struct ErrorFailureClassifierTests {
    private enum UnrelatedError: Error {
        case failed
    }

    private struct WrappedError: UnderlyingErrorProviding {
        let underlyingError: (any Error)?
    }

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

    @Test("Connectivity failures are reported as offline", arguments: [
        URLError.Code.notConnectedToInternet, .networkConnectionLost, .dataNotAllowed,
        .internationalRoamingOff, .cannotConnectToHost, .cannotFindHost, .timedOut,
    ])
    func connectivity(code: URLError.Code) {
        #expect(classifier.failure(for: URLError(code)) == .offline)
    }

    @Test("A connectivity failure wrapped in other errors is still reported as offline")
    func wrappedConnectivity() {
        #expect(classifier.failure(for: WrappedError(underlyingError: URLError(.timedOut))) == .offline)
        #expect(classifier.failure(for: WrappedError(underlyingError: WrappedError(underlyingError: URLError(.notConnectedToInternet)))) == .offline)
    }

    @Test("Other URL errors are reported as the service being unavailable", arguments: [
        URLError.Code.badURL, .unsupportedURL, .badServerResponse, .cannotDecodeContentData,
        .userAuthenticationRequired, .secureConnectionFailed, .fileDoesNotExist,
    ])
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
