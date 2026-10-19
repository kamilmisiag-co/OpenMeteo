//
//  RetryPolicyTests.swift
//  NetworkingTests
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation
import Networking
import NetworkingMocks
import Testing

@Suite("Retry policy")
struct RetryPolicyTests {
    private let policy = Fixtures.retryPolicy(maximumRetries: 4)
    private let get = NetworkFixtures.request(method: .get)
    private let unavailable = NetworkError.unacceptableStatusCode(NetworkFixtures.response(status: 503))

    @Test("Delays grow exponentially and stop at the maximum delay")
    func exponentialBackoff() {
        let delays = (1...4).map { policy.delay(beforeRetry: $0, of: get, after: unavailable) }
        #expect(delays == [.seconds(1), .seconds(2), .seconds(4), .seconds(8)])
        let capped = Fixtures.retryPolicy(maximumRetries: 6).delay(beforeRetry: 6, of: get, after: unavailable)
        #expect(capped == .seconds(10))
    }

    @Test("No retry once the maximum number of retries is used")
    func maximumRetries() {
        #expect(policy.delay(beforeRetry: 5, of: get, after: unavailable) == nil)
        #expect(policy.delay(beforeRetry: 0, of: get, after: unavailable) == nil)
    }

    @Test("Only the injected methods are retried")
    func retryableMethods() {
        #expect(policy.delay(beforeRetry: 1, of: NetworkFixtures.request(method: .post), after: unavailable) == nil)
        #expect(policy.delay(beforeRetry: 1, of: NetworkFixtures.request(method: .put), after: unavailable) == .seconds(1))
    }

    @Test("Only the injected status codes are retried", arguments: [(429, true), (501, false)])
    func retryableStatus(status: Int, retried: Bool) {
        let error = NetworkError.unacceptableStatusCode(NetworkFixtures.response(status: status))
        #expect((policy.delay(beforeRetry: 1, of: get, after: error) != nil) == retried)
    }

    @Test("Only the injected URL error codes are retried")
    func retryableTransportErrors() {
        #expect(policy.delay(beforeRetry: 1, of: get, after: .transport(URLError(.timedOut))) == .seconds(1))
        #expect(policy.delay(beforeRetry: 1, of: get, after: .transport(URLError(.badURL))) == nil)
    }

    @Test("Errors that can't succeed on retry are never retried")
    func nonRetryableErrors() {
        #expect(policy.delay(beforeRetry: 1, of: get, after: .nonHTTPResponse) == nil)
        #expect(policy.delay(beforeRetry: 1, of: get, after: .invalidURL(path: "x")) == nil)
        #expect(policy.delay(beforeRetry: 1, of: get, after: .decoding(underlying: CancellationError())) == nil)
    }

    private func rateLimited(retryAfter value: String) -> NetworkError {
        .unacceptableStatusCode(NetworkFixtures.response(status: 429, retryAfter: value))
    }

    @Test("Retry-After in seconds lengthens the delay")
    func retryAfterSeconds() {
        #expect(policy.delay(beforeRetry: 1, of: get, after: rateLimited(retryAfter: "3")) == .seconds(3))
        #expect(policy.delay(beforeRetry: 1, of: get, after: rateLimited(retryAfter: " 0 ")) == .seconds(1))
        #expect(policy.delay(beforeRetry: 1, of: get, after: rateLimited(retryAfter: "soon")) == .seconds(1))
    }

    @Test("Retry-After as an HTTP date is measured from the injected clock")
    func retryAfterDate() {
        #expect(policy.delay(beforeRetry: 1, of: get, after: rateLimited(retryAfter: "Fri, 16 Oct 2026 18:00:04 GMT")) == .seconds(4))
        #expect(policy.delay(beforeRetry: 1, of: get, after: rateLimited(retryAfter: "Fri, 16 Oct 2026 17:00:00 GMT")) == .seconds(1))
    }

    @Test("An HTTP-date Retry-After is measured against the response's own Date header")
    func retryAfterAgainstServerDate() {
        let error = NetworkError.unacceptableStatusCode(NetworkFixtures.response(status: 503, headers: [
            "Retry-After": "Fri, 16 Oct 2026 18:00:05 GMT",
            "Date": "Fri, 16 Oct 2026 17:59:57 GMT",
        ]))
        #expect(policy.delay(beforeRetry: 1, of: get, after: error) == .seconds(8))
    }

    @Test("Retry-After also accepts the RFC 850 and asctime date forms")
    func retryAfterObsoleteDates() {
        #expect(policy.delay(beforeRetry: 1, of: get, after: rateLimited(retryAfter: "Friday, 16-Oct-26 18:00:05 GMT")) == .seconds(5))
        #expect(policy.delay(beforeRetry: 1, of: get, after: rateLimited(retryAfter: "Fri Oct 16 18:00:06 2026")) == .seconds(6))
    }

    @Test("A server wait longer than the maximum delay gives up instead of retrying early")
    func retryAfterBeyondMaximum() {
        #expect(policy.delay(beforeRetry: 1, of: get, after: rateLimited(retryAfter: "60")) == nil)
        #expect(policy.delay(beforeRetry: 1, of: get, after: rateLimited(retryAfter: "99999999999999999999")) == nil)
        #expect(policy.delay(beforeRetry: 1, of: get, after: rateLimited(retryAfter: "Fri, 16 Oct 2026 18:05:00 GMT")) == nil)
    }

    @Test("Huge exponents and non-finite multipliers stop at the maximum delay instead of overflowing")
    func overflow() {
        #expect(Fixtures.retryPolicy(maximumRetries: 100).delay(beforeRetry: 70, of: get, after: unavailable) == .seconds(10))
        #expect(Fixtures.retryPolicy(maximumRetries: 3, multiplier: .infinity).delay(beforeRetry: 2, of: get, after: unavailable) == .seconds(10))
        #expect(Fixtures.retryPolicy(maximumRetries: 3, multiplier: .nan).delay(beforeRetry: 2, of: get, after: unavailable) == .seconds(10))
    }

    @Test("Jitter spreads the backoff using the injected random fraction")
    func jitter() {
        let full = Fixtures.retryPolicy(maximumRetries: 3, jitter: .full, randomFraction: 0.25)
        let equal = Fixtures.retryPolicy(maximumRetries: 3, jitter: .equal, randomFraction: 0.5)
        let outOfRange = Fixtures.retryPolicy(maximumRetries: 3, jitter: .full, randomFraction: 7)
        #expect(full.delay(beforeRetry: 3, of: get, after: unavailable) == .seconds(1))
        #expect(equal.delay(beforeRetry: 3, of: get, after: unavailable) == .seconds(3))
        #expect(outOfRange.delay(beforeRetry: 3, of: get, after: unavailable) == .seconds(4))
    }

    @Test("A random source that returns NaN can't crash the policy")
    func nanFraction() {
        let policy = Fixtures.retryPolicy(maximumRetries: 3, jitter: .equal, randomFraction: .nan)
        #expect(policy.delay(beforeRetry: 3, of: get, after: unavailable) == .seconds(4))
    }
}
