//
//  RetryPolicy.swift
//  Networking
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation
import Utils

public protocol RetryPolicy: Sendable {
    func delay(beforeRetry attempt: Int, of request: URLRequest, after error: NetworkError) -> Duration?
}

public struct NoRetryPolicy: RetryPolicy {
    public init() {}

    public func delay(beforeRetry attempt: Int, of request: URLRequest, after error: NetworkError) -> Duration? {
        nil
    }
}

public enum BackoffJitter: Hashable, Sendable {
    case none
    case full
    case equal
}

public struct ExponentialBackoffRetryPolicy: RetryPolicy {
    public typealias RandomFraction = @Sendable () -> Double
    public typealias Now = @Sendable () -> Date

    private static let httpDateStrategies = [
        Date.ParseStrategy(
            format: "\(weekday: .abbreviated), \(day: .twoDigits) \(month: .abbreviated) \(year: .defaultDigits) \(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits):\(second: .twoDigits) GMT",
            locale: Locale(identifier: "en_US_POSIX"),
            timeZone: .gmt
        ),
        Date.ParseStrategy(
            format: "\(weekday: .wide), \(day: .twoDigits)-\(month: .abbreviated)-\(year: .twoDigits) \(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits):\(second: .twoDigits) GMT",
            locale: Locale(identifier: "en_US_POSIX"),
            timeZone: .gmt
        ),
        Date.ParseStrategy(
            format: "\(weekday: .abbreviated) \(month: .abbreviated) \(day: .defaultDigits) \(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits):\(second: .twoDigits) \(year: .defaultDigits)",
            locale: Locale(identifier: "en_US_POSIX"),
            timeZone: .gmt
        ),
    ]

    private let maximumRetries: Int
    private let initialDelay: Duration
    private let multiplier: Double
    private let maximumDelay: Duration
    private let jitter: BackoffJitter
    private let randomFraction: RandomFraction
    private let now: Now
    private let retryableMethods: Set<HTTPMethod>
    private let retryableStatusCodes: Set<Int>
    private let retryableURLErrorCodes: Set<URLError.Code>

    public init(
        maximumRetries: Int,
        initialDelay: Duration,
        multiplier: Double,
        maximumDelay: Duration,
        jitter: BackoffJitter,
        randomFraction: @escaping RandomFraction,
        now: @escaping Now,
        retryableMethods: Set<HTTPMethod>,
        retryableStatusCodes: Set<Int>,
        retryableURLErrorCodes: Set<URLError.Code>
    ) {
        self.maximumRetries = maximumRetries
        self.initialDelay = initialDelay
        self.multiplier = multiplier
        self.maximumDelay = maximumDelay
        self.jitter = jitter
        self.randomFraction = randomFraction
        self.now = now
        self.retryableMethods = retryableMethods
        self.retryableStatusCodes = retryableStatusCodes
        self.retryableURLErrorCodes = retryableURLErrorCodes
    }

    public func delay(beforeRetry attempt: Int, of request: URLRequest, after error: NetworkError) -> Duration? {
        guard attempt >= 1, attempt <= maximumRetries,
              let method = request.httpMethod.flatMap(HTTPMethod.init(rawValue:)),
              retryableMethods.contains(method),
              isRetryable(error) else { return nil }
        let maximumSeconds = maximumDelay / .seconds(1)
        let backoffSeconds = jittered(min(exponentialSeconds(forAttempt: attempt), maximumSeconds))
        guard let retryAfterSeconds = retryAfterSeconds(in: error) else {
            return .seconds(backoffSeconds)
        }
        guard retryAfterSeconds <= maximumSeconds else { return nil }
        return .seconds(max(backoffSeconds, retryAfterSeconds))
    }

    private func exponentialSeconds(forAttempt attempt: Int) -> Double {
        let seconds = initialDelay / .seconds(1) * pow(multiplier, Double(attempt - 1))
        return seconds.isFinite ? max(0, seconds) : .infinity
    }

    private func jittered(_ seconds: Double) -> Double {
        switch jitter {
        case .none: seconds
        case .full: seconds * unitFraction()
        case .equal: seconds / 2 + seconds / 2 * unitFraction()
        }
    }

    private func unitFraction() -> Double {
        let fraction = randomFraction()
        return fraction.isNaN ? 1 : fraction.clamped(to: 0...1)
    }

    private func isRetryable(_ error: NetworkError) -> Bool {
        switch error {
        case .transport(let urlError): retryableURLErrorCodes.contains(urlError.code)
        case .unacceptableStatusCode(let response): retryableStatusCodes.contains(response.statusCode)
        case .invalidURL, .encoding, .nonHTTPResponse, .decoding: false
        }
    }

    private func retryAfterSeconds(in error: NetworkError) -> Double? {
        guard case .unacceptableStatusCode(let response) = error,
              let value = response.value(forHeader: HTTPHeaderField.retryAfter)?.trimmingCharacters(in: .whitespaces) else {
            return nil
        }
        if !value.isEmpty, value.allSatisfy({ $0.isASCII && $0.isWholeNumber }) {
            return Double(value)
        }
        guard let retryDate = httpDate(from: value) else { return nil }
        let reference = response.value(forHeader: HTTPHeaderField.date).flatMap(httpDate(from:)) ?? now()
        return max(0, retryDate.timeIntervalSince(reference))
    }

    private func httpDate(from value: String) -> Date? {
        Self.httpDateStrategies.lazy.compactMap { try? Date(value, strategy: $0) }.first
    }
}
