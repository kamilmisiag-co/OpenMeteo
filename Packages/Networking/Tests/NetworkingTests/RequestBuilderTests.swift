//
//  RequestBuilderTests.swift
//  NetworkingTests
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation
import Networking
import Testing

@Suite("Request builder")
struct RequestBuilderTests {
    @Test("Joins the base path with the endpoint path, with or without a leading slash")
    func joinsPaths() throws {
        let withSlash = try Fixtures.requestBuilder.makeRequest(for: CityEndpoint(name: "Lisbon"))
        let withoutSlash = try Fixtures.requestBuilder.makeRequest(for: CreateCityEndpoint(city: Fixtures.lisbon))
        #expect(withSlash.url?.host() == "api.example.test")
        #expect(withSlash.url?.path() == "/base/v1/cities")
        #expect(withoutSlash.url?.path() == "/base/v1/cities")
    }

    @Test("An empty path targets the base URL itself")
    func emptyPath() throws {
        let request = try Fixtures.requestBuilder.makeRequest(for: RootEndpoint())
        #expect(request.url == Fixtures.baseURL)
    }

    @Test("A trailing slash on the base URL doesn't double the separator")
    func trailingSlashBase() throws {
        let configuration = RequestConfiguration(
            baseURL: try #require(URL(string: "https://api.example.test/base/")),
            defaultHeaders: [:],
            timeout: .seconds(5),
            cachePolicy: .useProtocolCachePolicy
        )
        let builder = RequestBuilder(configuration: configuration, bodyEncoder: JSONBodyEncoder(encoder: Fixtures.jsonEncoder, contentType: "application/json"))
        let request = try builder.makeRequest(for: CityEndpoint(name: "Lisbon"))
        #expect(request.url?.path() == "/base/v1/cities")
        #expect(request.timeoutInterval == 5)
    }

    @Test("Appends query items and encodes their values")
    func queryItems() throws {
        let request = try Fixtures.requestBuilder.makeRequest(for: CityEndpoint(name: "Paris, France"))
        let url = try #require(request.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.queryItems == [URLQueryItem(name: "name", value: "Paris, France")])
        #expect(!url.absoluteString.contains(" "))
    }

    @Test("Plus signs, ampersands and equals signs in query values are encoded")
    func reservedCharactersInQuery() throws {
        let request = try Fixtures.requestBuilder.makeRequest(for: CityEndpoint(name: "C++ & a=b Etc/GMT+2"))
        let url = try #require(request.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.percentEncodedQuery == "name=C%2B%2B%20%26%20a%3Db%20Etc/GMT%2B2")
        #expect(components.queryItems == [URLQueryItem(name: "name", value: "C++ & a=b Etc/GMT+2")])
    }

    @Test("A query already in the base URL is left exactly as it was")
    func baseQueryUntouched() throws {
        let configuration = RequestConfiguration(
            baseURL: try #require(URL(string: "https://api.example.test/base?q=a+b")),
            defaultHeaders: [:],
            timeout: .seconds(5),
            cachePolicy: .useProtocolCachePolicy
        )
        let builder = RequestBuilder(configuration: configuration, bodyEncoder: JSONBodyEncoder(encoder: Fixtures.jsonEncoder, contentType: "application/json"))
        let request = try builder.makeRequest(for: CityEndpoint(name: "C+"))
        let url = try #require(request.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.percentEncodedQuery == "q=a+b&name=C%2B")
    }

    @Test("Takes method, timeout and cache policy from the endpoint and the configuration")
    func methodAndPolicies() throws {
        let request = try Fixtures.requestBuilder.makeRequest(for: CreateCityEndpoint(city: Fixtures.lisbon))
        #expect(request.httpMethod == "POST")
        #expect(request.timeoutInterval == 15)
        #expect(request.cachePolicy == .reloadIgnoringLocalCacheData)
    }

    @Test("Endpoint headers override default headers regardless of case")
    func headers() throws {
        let request = try Fixtures.requestBuilder.makeRequest(for: CityEndpoint(name: "Lisbon"))
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/vnd.test+json")
        #expect(request.value(forHTTPHeaderField: "X-Client") == "tests")
    }

    @Test("Encodable bodies use the injected encoder and its content type")
    func encodableBody() throws {
        let request = try Fixtures.requestBuilder.makeRequest(for: CreateCityEndpoint(city: Fixtures.lisbon))
        let body = try #require(request.httpBody)
        #expect(String(decoding: body, as: UTF8.self) == #"{"country_code":"PT","name":"Lisbon"}"#)
        #expect(request.value(forHTTPHeaderField: HTTPHeaderField.contentType) == "application/json")
    }

    @Test("Raw bodies keep their own content type unless the endpoint sets one")
    func rawBody() throws {
        let payload = Data([0x01, 0x02])
        let plain = try Fixtures.requestBuilder.makeRequest(for: UploadEndpoint(payload: payload, contentTypeOverride: nil))
        let overridden = try Fixtures.requestBuilder.makeRequest(for: UploadEndpoint(payload: payload, contentTypeOverride: "image/png"))
        #expect(plain.httpBody == payload)
        #expect(plain.value(forHTTPHeaderField: HTTPHeaderField.contentType) == "application/octet-stream")
        #expect(overridden.value(forHTTPHeaderField: HTTPHeaderField.contentType) == "image/png")
    }

    @Test("A body that can't be encoded is an encoding error")
    func encodingFailure() {
        let error = #expect(throws: NetworkError.self) {
            try Fixtures.requestBuilder.makeRequest(for: FailingBodyEndpoint())
        }
        #expect(error?.caseName == "encoding")
    }
}
