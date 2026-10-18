//
//  JSONValueCodingTests.swift
//  StorageTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic
import Storage
import Testing

@Suite("JSON value coding")
struct JSONValueCodingTests {
    private enum CodingFailure: Error, Hashable {
        case refused
    }

    private struct Reading: Codable, Hashable {
        let highCelsius: Double
        let fetchedAt: Date
    }

    private struct Unencodable: Encodable {
        func encode(to encoder: any Encoder) throws {
            throw CodingFailure.refused
        }
    }

    private static let reading = Reading(highCelsius: 21.5, fetchedAt: Date(timeIntervalSince1970: 1_000))
    private static let snakeCaseJSON = #"{"fetched_at":1000,"high_celsius":21.5}"#

    private static func snakeCaseEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = .sortedKeys
        return encoder
    }

    private static func snakeCaseDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }

    @Test("The encoder uses the injected key, date and formatting strategies")
    func encoderHonoursConfiguration() throws {
        let data = try JSONValueEncoder(encoder: Self.snakeCaseEncoder()).encode(Self.reading)
        #expect(String(decoding: data, as: UTF8.self) == Self.snakeCaseJSON)
    }

    @Test("The encoder uses the injected non-conforming float strategy")
    func encoderHonoursFloatStrategy() throws {
        let configured = JSONEncoder()
        configured.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "+Inf", negativeInfinity: "-Inf", nan: "NaN")

        let data = try JSONValueEncoder(encoder: configured).encode([Double.nan, .infinity])

        #expect(String(decoding: data, as: UTF8.self) == #"["NaN","+Inf"]"#)
        #expect(throws: EncodingError.self) {
            try JSONValueEncoder(encoder: JSONEncoder()).encode([Double.nan])
        }
    }

    @Test("Errors thrown while encoding a value reach the caller")
    func encoderPropagatesErrors() {
        #expect(throws: CodingFailure.refused) {
            try JSONValueEncoder(encoder: JSONEncoder()).encode(Unencodable())
        }
        #expect(throws: CodingFailure.refused) {
            try JSONValueEncoder(encoder: JSONEncoder()).encode([Unencodable()])
        }
    }

    @Test("The decoder uses the injected key and date strategies")
    func decoderHonoursConfiguration() throws {
        let data = Data(Self.snakeCaseJSON.utf8)

        #expect(try JSONValueDecoder(decoder: Self.snakeCaseDecoder()).decode(Reading.self, from: data) == Self.reading)
        #expect(throws: DecodingError.self) {
            try JSONValueDecoder(decoder: JSONDecoder()).decode(Reading.self, from: data)
        }
    }

    @Test(
        "Data that isn't the requested JSON shape throws a decoding error",
        arguments: ["", "not json", "{}", "[1,2,3]", #"{"fetched_at":1000}"#, #"{"fetched_at":"yesterday","high_celsius":21.5}"#]
    )
    func decoderPropagatesErrors(payload: String) {
        #expect(throws: DecodingError.self) {
            try JSONValueDecoder(decoder: Self.snakeCaseDecoder()).decode(Reading.self, from: Data(payload.utf8))
        }
    }

    @Test("A snapshot survives a round trip with sub-second dates and missing snow depths intact")
    func snapshotRoundTrip() throws {
        let snapshot = Fixtures.snapshot(for: Fixtures.zakopane)
        try #require(snapshot.fetchedAt.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1) != 0)
        try #require(snapshot.days.contains { $0.snowDepthCm == nil })
        try #require(snapshot.days.contains { $0.snowDepthCm != nil })

        let data = try JSONValueEncoder(encoder: JSONEncoder()).encode(snapshot)
        let decoded = try JSONValueDecoder(decoder: JSONDecoder()).decode(WeatherSnapshot.self, from: data)

        #expect(decoded == snapshot)
    }

    @Test("A list of cities survives a round trip in order")
    func citiesRoundTrip() throws {
        let cities = [Fixtures.bergen, Fixtures.lisbon, Fixtures.zakopane]
        let data = try JSONValueEncoder(encoder: JSONEncoder()).encode(cities)
        #expect(try JSONValueDecoder(decoder: JSONDecoder()).decode([City].self, from: data) == cities)
    }
}
