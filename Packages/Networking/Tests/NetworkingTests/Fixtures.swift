//
//  Fixtures.swift
//  NetworkingTests
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation
import Networking
import NetworkingMocks
import Utils
import UtilsMocks

struct TestCity: Codable, Hashable, Sendable {
    let name: String
    let countryCode: String
}

struct CityEndpoint: Endpoint {
    typealias Response = TestCity

    let name: String

    var method: HTTPMethod { .get }
    var path: String { "/v1/cities" }
    var queryItems: [URLQueryItem] { [URLQueryItem(name: "name", value: name)] }
    var headers: [String: String] { ["accept": "application/vnd.test+json"] }
}

struct CreateCityEndpoint: Endpoint {
    typealias Response = TestCity

    let city: TestCity

    var method: HTTPMethod { .post }
    var path: String { "v1/cities" }
    var body: RequestBody? { .encodable(city) }
}

struct UploadEndpoint: Endpoint {
    typealias Response = EmptyResponse

    let payload: Data
    let contentTypeOverride: String?

    var method: HTTPMethod { .put }
    var path: String { "/v1/upload" }
    var body: RequestBody? { .data(payload, contentType: "application/octet-stream") }
    var headers: [String: String] { contentTypeOverride.map { [HTTPHeaderField.contentType: $0] } ?? [:] }
}

struct RootEndpoint: Endpoint {
    typealias Response = EmptyResponse

    var method: HTTPMethod { .get }
    var path: String { "" }
}

struct MethodOverrideInterceptor: RequestInterceptor {
    let method: HTTPMethod

    func intercept(_ request: URLRequest) async throws -> URLRequest {
        var request = request
        request.httpMethod = method.rawValue
        return request
    }
}

actor CancellingTransport: HTTPTransport {
    private let response: HTTPResponse
    private(set) var requestCount = 0

    init(response: HTTPResponse) {
        self.response = response
    }

    func send(_ request: URLRequest) async throws -> HTTPResponse {
        requestCount += 1
        withUnsafeCurrentTask { $0?.cancel() }
        return response
    }
}

struct FailingEncodable: Encodable, Sendable {
    func encode(to encoder: any Encoder) throws {
        throw EncodingError.invalidValue(self, EncodingError.Context(codingPath: [], debugDescription: "Not encodable"))
    }
}

struct FailingBodyEndpoint: Endpoint {
    typealias Response = EmptyResponse

    var method: HTTPMethod { .post }
    var path: String { "/v1/failing" }
    var body: RequestBody? { .encodable(FailingEncodable()) }
}

enum Fixtures {
    static let lisbon = TestCity(name: "Lisbon", countryCode: "PT")
    static let lisbonJSON = Data(#"{"name":"Lisbon","country_code":"PT"}"#.utf8)

    static let configuration = RequestConfiguration(
        baseURL: NetworkFixtures.baseURL,
        defaultHeaders: ["Accept": "application/json", "X-Client": "tests"],
        timeout: .seconds(15),
        cachePolicy: .reloadIgnoringLocalCacheData
    )

    static var jsonEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = .sortedKeys
        return encoder
    }

    static var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    static var requestBuilder: RequestBuilder {
        RequestBuilder(configuration: configuration, encoder: jsonEncoder, contentType: "application/json")
    }

    static let now = Calendar.gregorian(timeZone: .gmt).date(year: 2026, month: 10, day: 16, hour: 18)

    static func retryPolicy(
        maximumRetries: Int,
        multiplier: Double = 2,
        jitter: BackoffJitter = .none,
        randomFraction: Double = 0
    ) -> ExponentialBackoffRetryPolicy {
        ExponentialBackoffRetryPolicy(
            maximumRetries: maximumRetries,
            initialDelay: .seconds(1),
            multiplier: multiplier,
            maximumDelay: .seconds(10),
            jitter: jitter,
            randomFraction: { randomFraction },
            dateProvider: ManualDateProvider(now: now),
            retryableMethods: [.get, .head, .put, .delete],
            retryableStatusCodes: [429, 500, 502, 503, 504],
            retryableURLErrorCodes: [.timedOut, .networkConnectionLost, .notConnectedToInternet]
        )
    }

    static func client(
        transport: any HTTPTransport,
        retryPolicy: any RetryPolicy = NoRetryPolicy(),
        sleeper: any Sleeping = RecordingSleeper(),
        interceptors: [any RequestInterceptor] = [],
        observers: [any NetworkObserver] = []
    ) -> NetworkClient {
        NetworkClient(
            requestBuilder: requestBuilder,
            interceptors: interceptors,
            transport: transport,
            validator: StatusCodeValidator(acceptableStatusCodes: 200..<300),
            decoder: jsonDecoder,
            retryPolicy: retryPolicy,
            sleeper: sleeper,
            observers: observers
        )
    }
}
