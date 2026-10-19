//
//  OpenMeteoStandardTests.swift
//  OpenMeteoAPITests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Networking
import NetworkingMocks
import OpenMeteoAPI
import Testing

@Suite("Open-Meteo standard presets")
struct OpenMeteoStandardTests {
    private let policy = Fixtures.retryPolicy(randomFraction: { 1 })

    @Test("Talks to the public Open-Meteo hosts over HTTPS with a 15 second timeout")
    func hosts() {
        #expect(OpenMeteoStandard.geocodingBaseURL.absoluteString == "https://geocoding-api.open-meteo.com")
        #expect(OpenMeteoStandard.forecastBaseURL.absoluteString == "https://api.open-meteo.com")
        #expect(OpenMeteoStandard.requestTimeout == .seconds(15))
    }

    @Test("A rate limit without Retry-After is retried after the initial delay", arguments: [429])
    func retriedStatus(status: Int) {
        let delay = policy.delay(beforeRetry: 1, of: request(.get), after: .unacceptableStatusCode(response(status: status)))
        #expect(delay == .milliseconds(500))
    }

    @Test("Client errors are not retried", arguments: [400])
    func clientErrorStatus(status: Int) {
        #expect(policy.delay(beforeRetry: 1, of: request(.get), after: .unacceptableStatusCode(response(status: status))) == nil)
    }

    @Test("A dropped connection is retried after the initial delay")
    func connectionLost() {
        let delay = policy.delay(beforeRetry: 1, of: request(.get), after: .transport(URLError(.networkConnectionLost)))
        #expect(delay == .milliseconds(500))
    }

    @Test("Being offline fails fast so the cache can take over", arguments: [URLError.Code.notConnectedToInternet])
    func failFastTransport(code: URLError.Code) {
        #expect(policy.delay(beforeRetry: 1, of: request(.get), after: .transport(URLError(code))) == nil)
    }

    @Test("A request other than GET is not retried", arguments: [HTTPMethod.post])
    func nonGetMethods(method: HTTPMethod) {
        #expect(policy.delay(beforeRetry: 1, of: request(method), after: .unacceptableStatusCode(response(status: 503))) == nil)
    }

    @Test("The first delay is the initial delay, the second doubles it and the attempt after the last retry gives up")
    func backoffSchedule() {
        let get = request(.get)
        let unavailable = NetworkError.unacceptableStatusCode(response(status: 503))
        let delays = (1...OpenMeteoStandard.maximumRetries + 1).map { policy.delay(beforeRetry: $0, of: get, after: unavailable) }
        #expect(delays == [.milliseconds(500), .seconds(1), nil])
    }

    @Test("Equal jitter keeps half of the backoff and scales the other half by the injected random fraction", arguments: [
        (0.0, Duration.milliseconds(250)),
        (0.5, Duration.milliseconds(375)),
        (1.0, Duration.milliseconds(500)),
    ])
    func jitter(fraction: Double, expected: Duration) {
        let jittered = Fixtures.retryPolicy(randomFraction: { fraction })
        #expect(jittered.delay(beforeRetry: 1, of: request(.get), after: .unacceptableStatusCode(response(status: 503))) == expected)
    }

    @Test("A Retry-After within the maximum delay replaces a shorter backoff and a longer one gives up")
    func retryAfterSeconds() {
        let get = request(.get)
        #expect(policy.delay(beforeRetry: 1, of: get, after: .unacceptableStatusCode(response(status: 429, retryAfter: "3"))) == .seconds(3))
        #expect(policy.delay(beforeRetry: 1, of: get, after: .unacceptableStatusCode(response(status: 429, retryAfter: "8"))) == .seconds(8))
        #expect(policy.delay(beforeRetry: 1, of: get, after: .unacceptableStatusCode(response(status: 429, retryAfter: "9"))) == nil)
    }

    private func request(_ method: HTTPMethod) -> URLRequest {
        NetworkFixtures.request(method: method, url: OpenMeteoStandard.forecastBaseURL.appending(path: "v1/forecast"))
    }

    private func response(status: Int, retryAfter: String? = nil) -> HTTPResponse {
        NetworkFixtures.response(status: status, retryAfter: retryAfter)
    }
}
