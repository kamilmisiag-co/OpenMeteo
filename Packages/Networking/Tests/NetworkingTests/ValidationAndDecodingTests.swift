//
//  ValidationAndDecodingTests.swift
//  NetworkingTests
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation
import Networking
import NetworkingMocks
import Testing
import UtilsMocks

@Suite("Validation and decoding")
struct ValidationAndDecodingTests {
    @Test("Status codes inside the injected range pass")
    func acceptsStatus() throws {
        try StatusCodeValidator(acceptableStatusCodes: 200..<300).validate(NetworkFixtures.response(status: 200))
    }

    @Test("Status codes outside the range carry the full response")
    func rejectsStatus() {
        let error = #expect(throws: NetworkError.self) {
            try StatusCodeValidator(acceptableStatusCodes: 200..<300).validate(NetworkFixtures.response(status: 404))
        }
        #expect(error?.statusCode == 404)
    }

    @Test("Decodable endpoints decode the body with the injected decoder")
    func decodesWithStrategy() throws {
        let city = try CityEndpoint(name: "Lisbon").decode(NetworkFixtures.response(body: Fixtures.lisbonJSON), using: Fixtures.jsonDecoder)
        #expect(city == Fixtures.lisbon)
    }

    @Test("Any decoder failure becomes a decoding error that keeps the original error")
    func decoderFailureWrapped() {
        let error = #expect(throws: NetworkError.self) {
            try CityEndpoint(name: "Lisbon").decode(NetworkFixtures.response(body: Fixtures.lisbonJSON), using: FailingDataDecoder())
        }
        #expect(error?.caseName == "decoding")
        #expect(error?.underlyingError is UnrelatedError)
    }
}
