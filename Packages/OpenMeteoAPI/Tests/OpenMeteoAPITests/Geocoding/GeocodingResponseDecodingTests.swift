//
//  GeocodingResponseDecodingTests.swift
//  OpenMeteoAPITests
//
//  Created by Kamil Misiag on 19/10/2026.
//

import OpenMeteoAPI
import Testing

@Suite("Geocoding response decoding")
struct GeocodingResponseDecodingTests {
    @Test(
        "Every geocoding fixture decodes all of its results",
        arguments: [
            (Fixtures.File.geocodingLisbon, 10),
            (.geocodingSaoPaulo, 10),
            (.geocodingMissingCountry, 3),
            (.geocodingNoMatches, 0),
        ]
    )
    func geocodingResultCounts(file: Fixtures.File, count: Int) throws {
        let response = try Fixtures.decode(GeocodingResponseDTO.self, from: file)
        #expect(response.results.count == count)
    }

    @Test("A geocoding result without a country decodes with a nil country")
    func missingCountry() throws {
        let results = try Fixtures.decode(GeocodingResponseDTO.self, from: .geocodingMissingCountry).results
        let sanJuan = try #require(results.first)
        #expect(results.map(\.id) == [4_568_127, 5_391_811, 2_451_778])
        #expect(results.map(\.country) == [nil, "United States", "Mali"])
        #expect(sanJuan.name == "San Juan")
        #expect(sanJuan.countryCode == "PR")
        #expect(sanJuan.admin1 == "San Juan")
        #expect(sanJuan.timezone == "America/Puerto_Rico")
        #expect(sanJuan.latitude == 18.46633)
        #expect(sanJuan.longitude == -66.10572)
    }

    @Test("Every São Paulo result decodes in the API's order, look-alike duplicates included")
    func saoPaulo() throws {
        let results = try Fixtures.decode(GeocodingResponseDTO.self, from: .geocodingSaoPaulo).results
        #expect(results.map(\.id) == [
            3_448_439, 3_462_944, 3_401_050, 3_468_689, 13_645_899, 2_263_259, 2_410_768, 2_734_380, 2_734_381, 3_388_241,
        ])
        #expect(results.map(\.name) == [
            "São Paulo", "Frei Paulo", "Diamante", "Caatiba", "São Paulo", "São Paulo", "São Paulo", "São Paulo", "São Paulo", "São Paulo",
        ])
        #expect(results.map(\.countryCode) == ["BR", "BR", "BR", "BR", "CV", "PT", "ST", "PT", "PT", "BR"])
        #expect(results.map(\.country) == [
            "Brazil", "Brazil", "Brazil", "Brazil", "Cabo Verde", "Portugal", "São Tomé and Príncipe", "Portugal", "Portugal", "Brazil",
        ])
        #expect(results.map(\.admin1) == [
            "São Paulo", "Sergipe", "Paraíba", "Estado de Bahia", "Sal", "Coimbra District", "São Tomé Island",
            "Coimbra District", "Coimbra District", "Alagoas",
        ])
        let first = try #require(results.first)
        #expect(first.latitude == -23.5475)
        #expect(first.longitude == -46.63611)
        #expect(first.timezone == "America/Sao_Paulo")
    }

    @Test("A geocoding response whose every result is malformed fails to decode instead of reading as no matches")
    func allResultsMalformed() {
        #expect(throws: DecodingError.self) {
            try Fixtures.decode(GeocodingResponseDTO.self, json: #"""
            {"results": [{"name": "No identifier", "latitude": 1.0, "longitude": 2.0}, {"id": "x", "name": "Bad", "latitude": 3.0, "longitude": 4.0}]}
            """#)
        }
    }

    @Test("A result missing a required field is dropped and the other results are kept")
    func lossyResults() throws {
        let response = try Fixtures.decode(GeocodingResponseDTO.self, json: #"""
        {"results": [
            {"id": 1, "name": "Alpha", "latitude": 1.0, "longitude": 2.0},
            {"name": "No identifier", "latitude": 3.0, "longitude": 4.0},
            {"id": 3, "name": "Gamma", "latitude": 5.0, "longitude": 6.0}
        ]}
        """#)
        #expect(response.results.map(\.id) == [1, 3])
    }
}
