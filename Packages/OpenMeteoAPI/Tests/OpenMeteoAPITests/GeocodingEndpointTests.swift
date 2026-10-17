//
//  GeocodingEndpointTests.swift
//  OpenMeteoAPITests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Networking
import OpenMeteoAPI
import Synchronization
import Testing

@Suite("Geocoding endpoint")
struct GeocodingEndpointTests {
    private final class RecordingResponseDecoder<Sentinel: Sendable>: ResponseDecoding {
        struct Call: Hashable, Sendable {
            let type: ObjectIdentifier
            let data: Data
        }

        private let sentinel: Sentinel
        private let received = Mutex<[Call]>([])

        init(sentinel: Sentinel) {
            self.sentinel = sentinel
        }

        var calls: [Call] {
            received.withLock { $0 }
        }

        func decode<Value: Decodable>(_ type: Value.Type, from data: Data) throws -> Value {
            received.withLock { $0.append(Call(type: ObjectIdentifier(type), data: data)) }
            return try #require(sentinel as? Value)
        }
    }

    private struct DecoderFailure: Error, Equatable {}

    private struct FailingResponseDecoder: ResponseDecoding {
        func decode<Value: Decodable>(_ type: Value.Type, from data: Data) throws -> Value {
            throw DecoderFailure()
        }
    }

    @Test("Searches with GET on the v1/search path without headers or a body")
    func methodAndPath() {
        let endpoint = GeocodingEndpoint(name: "Lisbon", resultLimit: 10, languageCode: "en")
        #expect(endpoint.method == .get)
        #expect(endpoint.path == "v1/search")
        #expect(endpoint.headers.isEmpty)
        #expect(endpoint.body == nil)
    }

    @Test("Keeps the name, result limit and language code it was built with")
    func storedValues() {
        let endpoint = GeocodingEndpoint(name: "São Paulo", resultLimit: 25, languageCode: "pt")
        #expect(endpoint.name == "São Paulo")
        #expect(endpoint.resultLimit == 25)
        #expect(endpoint.languageCode == "pt")
    }

    @Test("Sends the name, result limit, language and JSON format in that order")
    func queryItems() {
        let endpoint = GeocodingEndpoint(name: "São Paulo", resultLimit: 25, languageCode: "pt")
        #expect(endpoint.queryItems == [
            URLQueryItem(name: "name", value: "São Paulo"),
            URLQueryItem(name: "count", value: "25"),
            URLQueryItem(name: "language", value: "pt"),
            URLQueryItem(name: "format", value: "json"),
        ])
    }

    @Test(
        "Sends the result limit and language code exactly as given, leaving clamping and normalising to the request factory",
        arguments: [(0, "PT"), (-5, "pt-BR"), (101, "EN"), (Int.max, "zh"), (Int.min, "")]
    )
    func passesValuesThrough(resultLimit: Int, languageCode: String) {
        let endpoint = GeocodingEndpoint(name: "Lisbon", resultLimit: resultLimit, languageCode: languageCode)
        #expect(endpoint.resultLimit == resultLimit)
        #expect(endpoint.languageCode == languageCode)
        #expect(endpoint.queryItems.first { $0.name == "count" }?.value == String(resultLimit))
        #expect(endpoint.queryItems.first { $0.name == "language" }?.value == languageCode)
    }

    @Test(
        "Builds the search URL on the geocoding host with the name percent-encoded",
        arguments: [
            ("Lisbon", "https://geocoding-api.open-meteo.com/v1/search?name=Lisbon&count=10&language=en&format=json"),
            ("São Paulo", "https://geocoding-api.open-meteo.com/v1/search?name=S%C3%A3o%20Paulo&count=10&language=en&format=json"),
            ("Sao+Paulo", "https://geocoding-api.open-meteo.com/v1/search?name=Sao%2BPaulo&count=10&language=en&format=json"),
            ("Lisbon, Portugal", "https://geocoding-api.open-meteo.com/v1/search?name=Lisbon,%20Portugal&count=10&language=en&format=json"),
            ("Biel/Bienne", "https://geocoding-api.open-meteo.com/v1/search?name=Biel/Bienne&count=10&language=en&format=json"),
            ("Trinidad & Tobago", "https://geocoding-api.open-meteo.com/v1/search?name=Trinidad%20%26%20Tobago&count=10&language=en&format=json"),
        ]
    )
    func url(name: String, expected: String) throws {
        let request = try builtRequest(for: GeocodingEndpoint(name: name, resultLimit: 10, languageCode: "en"))
        #expect(request.url?.absoluteString == expected)
    }

    @Test("Sends São Paulo percent-encoded in Portuguese")
    func localizedSearchURL() throws {
        let request = try builtRequest(for: GeocodingEndpoint(name: "São Paulo", resultLimit: 10, languageCode: "pt"))
        #expect(request.url?.absoluteString == "https://geocoding-api.open-meteo.com/v1/search?name=S%C3%A3o%20Paulo&count=10&language=pt&format=json")
    }

    @Test("Builds a GET request with a 15 second timeout, no headers and no body")
    func requestShape() throws {
        let request = try builtRequest(for: GeocodingEndpoint(name: "Lisbon", resultLimit: 10, languageCode: "en"))
        #expect(request.httpMethod == "GET")
        #expect(request.timeoutInterval == 15)
        #expect((request.allHTTPHeaderFields ?? [:]).isEmpty)
        #expect(request.httpBody == nil)
    }

    @Test("Decoding hands the response body to the injected decoder and returns exactly what it decodes")
    func decodesThroughInjectedDecoder() throws {
        let sentinel = try Fixtures.decode(GeocodingResponseDTO.self, from: .geocodingSaoPaulo)
        let response = try Fixtures.response(.geocodingLisbon)
        let decoder = RecordingResponseDecoder(sentinel: sentinel)
        let endpoint = GeocodingEndpoint(name: "Lisbon", resultLimit: 10, languageCode: "en")
        let bodyDecodedDirectly = try Fixtures.decode(GeocodingResponseDTO.self, from: .geocodingLisbon)

        let decoded = try endpoint.decode(response, using: decoder)

        #expect(decoded == sentinel)
        #expect(decoded != bodyDecodedDirectly)
        #expect(decoder.calls == [.init(type: ObjectIdentifier(GeocodingResponseDTO.self), data: response.body)])
    }

    @Test("A failure from the injected decoder reaches the caller instead of falling back to another decoder")
    func injectedDecoderFailure() throws {
        let endpoint = GeocodingEndpoint(name: "Lisbon", resultLimit: 10, languageCode: "en")
        let response = try Fixtures.response(.geocodingLisbon)
        #expect(throws: DecoderFailure()) {
            try endpoint.decode(response, using: FailingResponseDecoder())
        }
    }

    private func builtRequest(for endpoint: GeocodingEndpoint) throws -> URLRequest {
        try Fixtures.requestBuilder(host: OpenMeteoStandard.geocodingHost).makeRequest(for: endpoint)
    }
}
