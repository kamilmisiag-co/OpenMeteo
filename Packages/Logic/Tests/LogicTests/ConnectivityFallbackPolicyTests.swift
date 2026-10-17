//
//  ConnectivityFallbackPolicyTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Logic
import Testing
import Utils

@Suite("Connectivity fallback policy")
struct ConnectivityFallbackPolicyTests {
    private enum UnrelatedError: Error {
        case failed
    }

    private struct WrappedError: UnderlyingErrorProviding {
        let underlyingError: (any Error)?
    }

    private let policy = ConnectivityFallbackPolicy()

    @Test("Connectivity failures allow the cached forecast", arguments: [
        URLError.Code.notConnectedToInternet, .networkConnectionLost, .dataNotAllowed,
        .internationalRoamingOff, .cannotConnectToHost, .cannotFindHost, .timedOut,
    ])
    func connectivity(code: URLError.Code) {
        #expect(policy.allowsCachedForecast(after: URLError(code)))
    }

    @Test("Other URL errors don't allow the cached forecast", arguments: [
        URLError.Code.badURL, .unsupportedURL, .badServerResponse, .cannotDecodeContentData,
        .userAuthenticationRequired, .secureConnectionFailed, .fileDoesNotExist,
    ])
    func otherURLErrors(code: URLError.Code) {
        #expect(!policy.allowsCachedForecast(after: URLError(code)))
    }

    @Test("Cancellation never allows the cached forecast")
    func cancellation() {
        #expect(!policy.allowsCachedForecast(after: CancellationError()))
        #expect(!policy.allowsCachedForecast(after: URLError(.cancelled)))
        #expect(!policy.allowsCachedForecast(after: WrappedError(underlyingError: CancellationError())))
    }

    @Test("Errors unrelated to connectivity don't allow the cached forecast")
    func unrelatedErrors() {
        #expect(!policy.allowsCachedForecast(after: UnrelatedError.failed))
        #expect(!policy.allowsCachedForecast(after: ForecastError.noUpcomingDays))
        #expect(!policy.allowsCachedForecast(after: WrappedError(underlyingError: nil)))
        #expect(!policy.allowsCachedForecast(after: WrappedError(underlyingError: UnrelatedError.failed)))
    }

    @Test("A connectivity failure wrapped in other errors still allows the cached forecast")
    func wrappedConnectivity() {
        #expect(policy.allowsCachedForecast(after: WrappedError(underlyingError: URLError(.timedOut))))
        #expect(policy.allowsCachedForecast(after: WrappedError(underlyingError: WrappedError(underlyingError: URLError(.notConnectedToInternet)))))
    }
}
