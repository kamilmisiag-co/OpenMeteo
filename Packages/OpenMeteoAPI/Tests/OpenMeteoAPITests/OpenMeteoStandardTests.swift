//
//  OpenMeteoStandardTests.swift
//  OpenMeteoAPITests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Networking
import OpenMeteoAPI
import Testing
import UtilsMocks

@Suite("Open-Meteo standard presets")
struct OpenMeteoStandardTests {
    private let policy = Fixtures.retryPolicy(randomFraction: { 1 })

    @Test("Talks to the public Open-Meteo hosts over HTTPS with a 15 second timeout")
    func hosts() {
        #expect(OpenMeteoStandard.scheme == "https")
        #expect(OpenMeteoStandard.geocodingHost == "geocoding-api.open-meteo.com")
        #expect(OpenMeteoStandard.forecastHost == "api.open-meteo.com")
        #expect(OpenMeteoStandard.requestTimeout == .seconds(15))
    }

    @Test("Searches for ten results within the API's range of 1 to 100, with English as the fallback language")
    func geocodingPresets() {
        #expect(OpenMeteoStandard.geocodingResultLimit == 10)
        #expect(OpenMeteoStandard.geocodingResultLimits == 1...100)
        #expect(OpenMeteoStandard.geocodingResultLimits.contains(OpenMeteoStandard.geocodingResultLimit))
        #expect(OpenMeteoStandard.fallbackLanguageCode == "en")
    }

    @Test("Asks for one extra day, at most sixteen, and lets the server pick the zone when the city has none")
    func forecastPresets() {
        #expect(OpenMeteoStandard.additionalForecastDays == 1)
        #expect(OpenMeteoStandard.maximumForecastDays == 16)
        #expect(OpenMeteoStandard.timeZoneFallbackIdentifier == "auto")
    }

    @Test("Converts percentages to fractions and metres of snow depth to centimetres")
    func forecastUnits() {
        #expect(OpenMeteoStandard.forecastUnits == ForecastUnits(percentPerFraction: 100, centimetresPerSnowDepthUnit: 100))
        #expect(OpenMeteoStandard.forecastUnits.percentPerFraction == 100)
        #expect(OpenMeteoStandard.forecastUnits.centimetresPerSnowDepthUnit == 100)
    }

    @Test("Retries GET twice with equal-jitter backoff from half a second up to eight seconds")
    func retryPresets() {
        #expect(OpenMeteoStandard.maximumRetries == 2)
        #expect(OpenMeteoStandard.initialRetryDelay == .milliseconds(500))
        #expect(OpenMeteoStandard.retryDelayMultiplier == 2)
        #expect(OpenMeteoStandard.maximumRetryDelay == .seconds(8))
        #expect(OpenMeteoStandard.retryJitter == .equal)
        #expect(OpenMeteoStandard.retryableMethods == [.get])
        #expect(OpenMeteoStandard.retryableStatusCodes == [408, 429, 500, 502, 503, 504])
        #expect(OpenMeteoStandard.retryableURLErrorCodes == [.networkConnectionLost])
    }

    @Test("Timeouts, rate limits and transient server errors are retried after the initial delay", arguments: [503, 500, 502, 504, 408, 429])
    func retriedStatus(status: Int) throws {
        let delay = policy.delay(beforeRetry: 1, of: try request(.get), after: .unacceptableStatusCode(response(status: status)))
        #expect(delay == .milliseconds(500))
    }

    @Test("Client errors are not retried", arguments: [400, 404])
    func clientErrorStatus(status: Int) throws {
        #expect(policy.delay(beforeRetry: 1, of: try request(.get), after: .unacceptableStatusCode(response(status: status))) == nil)
    }

    @Test("The recorded overload response is retried after the initial delay")
    func overloadedFixture() throws {
        let overloaded = try Fixtures.response(.forecastErrorOverloaded, status: 503)
        #expect(policy.delay(beforeRetry: 1, of: try request(.get), after: .unacceptableStatusCode(overloaded)) == .milliseconds(500))
    }

    @Test("A dropped connection is retried after the initial delay")
    func connectionLost() throws {
        let delay = policy.delay(beforeRetry: 1, of: try request(.get), after: .transport(URLError(.networkConnectionLost)))
        #expect(delay == .milliseconds(500))
    }

    @Test("Offline, timed out and unknown host failures fail fast so the cache can take over", arguments: [
        URLError.Code.notConnectedToInternet,
        .timedOut,
        .cannotFindHost,
    ])
    func failFastTransport(code: URLError.Code) throws {
        #expect(policy.delay(beforeRetry: 1, of: try request(.get), after: .transport(URLError(code))) == nil)
    }

    @Test("Errors a retry can't fix are never retried")
    func nonRetryableErrors() throws {
        let get = try request(.get)
        #expect(policy.delay(beforeRetry: 1, of: get, after: .nonHTTPResponse) == nil)
        #expect(policy.delay(beforeRetry: 1, of: get, after: .invalidURL(path: "v1/forecast")) == nil)
        #expect(policy.delay(beforeRetry: 1, of: get, after: .decoding(underlying: CancellationError())) == nil)
    }

    @Test("Only GET requests are retried", arguments: HTTPMethod.allCases.filter { $0 != .get })
    func nonGetMethods(method: HTTPMethod) throws {
        #expect(policy.delay(beforeRetry: 1, of: try request(method), after: .unacceptableStatusCode(response(status: 503))) == nil)
    }

    @Test("A POST is never retried, whatever the failure")
    func postNeverRetried() throws {
        let post = try request(.post)
        #expect(policy.delay(beforeRetry: 1, of: post, after: .unacceptableStatusCode(response(status: 503))) == nil)
        #expect(policy.delay(beforeRetry: 1, of: post, after: .unacceptableStatusCode(response(status: 429, retryAfter: "1"))) == nil)
        #expect(policy.delay(beforeRetry: 1, of: post, after: .transport(URLError(.networkConnectionLost))) == nil)
    }

    @Test("The first delay is the initial delay, the second doubles it and the attempt after the last retry gives up")
    func backoffSchedule() throws {
        let get = try request(.get)
        let unavailable = NetworkError.unacceptableStatusCode(response(status: 503))
        let delays = (1...OpenMeteoStandard.maximumRetries + 1).map { policy.delay(beforeRetry: $0, of: get, after: unavailable) }
        #expect(delays == [.milliseconds(500), .seconds(1), nil])
    }

    @Test("Equal jitter keeps half of the backoff and scales the other half by the injected random fraction", arguments: [
        (0.0, Duration.milliseconds(250)),
        (0.5, Duration.milliseconds(375)),
        (1.0, Duration.milliseconds(500)),
    ])
    func jitter(fraction: Double, expected: Duration) throws {
        let jittered = Fixtures.retryPolicy(randomFraction: { fraction })
        #expect(jittered.delay(beforeRetry: 1, of: try request(.get), after: .unacceptableStatusCode(response(status: 503))) == expected)
    }

    @Test("A Retry-After within the maximum delay replaces a shorter backoff and a longer one gives up")
    func retryAfterSeconds() throws {
        let get = try request(.get)
        #expect(policy.delay(beforeRetry: 1, of: get, after: .unacceptableStatusCode(response(status: 429, retryAfter: "3"))) == .seconds(3))
        #expect(policy.delay(beforeRetry: 1, of: get, after: .unacceptableStatusCode(response(status: 429, retryAfter: "8"))) == .seconds(8))
        #expect(policy.delay(beforeRetry: 1, of: get, after: .unacceptableStatusCode(response(status: 429, retryAfter: "9"))) == nil)
    }

    @Test("A Retry-After date is measured from the injected clock")
    func retryAfterDate() throws {
        let get = try request(.get)
        let rateLimited = response(status: 429, retryAfter: "Thu, 01 Jan 1970 00:00:04 GMT")
        let later = Fixtures.retryPolicy(dateProvider: ManualDateProvider(now: Date(timeIntervalSince1970: 1)))
        #expect(policy.delay(beforeRetry: 1, of: get, after: .unacceptableStatusCode(rateLimited)) == .seconds(4))
        #expect(later.delay(beforeRetry: 1, of: get, after: .unacceptableStatusCode(rateLimited)) == .seconds(3))
    }

    private func request(_ method: HTTPMethod) throws -> URLRequest {
        var request = URLRequest(url: try Fixtures.baseURL(host: OpenMeteoStandard.forecastHost).appending(path: "v1/forecast"))
        request.httpMethod = method.rawValue
        return request
    }

    private func response(status: Int, retryAfter: String? = nil) -> HTTPResponse {
        HTTPResponse(statusCode: status, headers: retryAfter.map { ["Retry-After": $0] } ?? [:], body: Data(), url: nil)
    }
}
