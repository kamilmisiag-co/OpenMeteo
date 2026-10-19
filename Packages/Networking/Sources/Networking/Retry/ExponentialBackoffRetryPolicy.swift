//
//  ExponentialBackoffRetryPolicy.swift
//  Networking
//
//  Created by Kamil Misiag on 19/10/2026.
//

import Foundation
import Utils

public struct ExponentialBackoffRetryPolicy: RetryPolicy {
    public typealias RandomFraction = @Sendable () -> Double

    private static let httpDateStrategies = [
        "\(weekday: .abbreviated), \(day: .twoDigits) \(month: .abbreviated) \(year: .defaultDigits) \(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits):\(second: .twoDigits) GMT",
        "\(weekday: .wide), \(day: .twoDigits)-\(month: .abbreviated)-\(year: .twoDigits) \(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits):\(second: .twoDigits) GMT",
        "\(weekday: .abbreviated) \(month: .abbreviated) \(day: .defaultDigits) \(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits):\(second: .twoDigits) \(year: .defaultDigits)",
    ].map { (format: Date.FormatString) in
        Date.ParseStrategy(format: format, locale: Locale(identifier: "en_US_POSIX"), timeZone: .gmt)
    }

    private let maximumRetries: Int
    private let initialDelay: Duration
    private let multiplier: Double
    private let maximumDelay: Duration
    private let jitter: BackoffJitter
    private let randomFraction: RandomFraction
    private let dateProvider: any DateProviding
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
        dateProvider: any DateProviding,
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
        self.dateProvider = dateProvider
        self.retryableMethods = retryableMethods
        self.retryableStatusCodes = retryableStatusCodes
        self.retryableURLErrorCodes = retryableURLErrorCodes
    }

    public func delay(beforeRetry attempt: Int, of request: URLRequest, after error: NetworkError) -> Duration? {
        guard attempt >= 1, attempt <= maximumRetries,
              let method = request.httpMethod.flatMap(HTTPMethod.init(rawValue:)),
              retryableMethods.contains(method),
              isRetryable(error) else { return nil }
        let maximumSeconds = maximumDelay.timeInterval
        let backoffSeconds = jittered(min(exponentialSeconds(forAttempt: attempt), maximumSeconds))
        guard let retryAfterSeconds = retryAfterSeconds(in: error) else {
            return .seconds(backoffSeconds)
        }
        guard retryAfterSeconds <= maximumSeconds else { return nil }
        return .seconds(max(backoffSeconds, retryAfterSeconds))
    }

    private func exponentialSeconds(forAttempt attempt: Int) -> Double {
        let seconds = initialDelay.timeInterval * pow(multiplier, Double(attempt - 1))
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
        randomFraction().clamped(to: 0...1, ifNaN: 1)
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
        if value.isASCIIDigits {
            return Double(value)
        }
        guard let retryDate = httpDate(from: value) else { return nil }
        let reference = response.value(forHeader: HTTPHeaderField.date).flatMap(httpDate(from:)) ?? dateProvider.now()
        return max(0, retryDate.timeIntervalSince(reference))
    }

    private func httpDate(from value: String) -> Date? {
        Self.httpDateStrategies.lazy.compactMap { try? Date(value, strategy: $0) }.first
    }
}
