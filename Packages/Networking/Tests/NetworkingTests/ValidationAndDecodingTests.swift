//
//  ValidationAndDecodingTests.swift
//  NetworkingTests
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation
import Networking
import Testing

@Suite("Validation and decoding")
struct ValidationAndDecodingTests {
    @Test("Status codes inside the injected range pass", arguments: [200, 204, 299])
    func acceptsStatus(status: Int) throws {
        try StatusCodeValidator(acceptableStatusCodes: 200..<300).validate(Fixtures.response(status: status))
    }

    @Test("Status codes outside the range carry the full response", arguments: [199, 301, 404, 503])
    func rejectsStatus(status: Int) {
        let error = #expect(throws: NetworkError.self) {
            try StatusCodeValidator(acceptableStatusCodes: 200..<300).validate(Fixtures.response(status: status))
        }
        #expect(error?.statusCode == status)
    }

    @Test("The JSON decoder uses the injected decoding strategy")
    func decodesWithStrategy() throws {
        let city = try JSONResponseDecoder(decoder: Fixtures.jsonDecoder).decode(TestCity.self, from: Fixtures.lisbonJSON)
        #expect(city == Fixtures.lisbon)
    }

    @Test("Malformed JSON is a decoding error")
    func decodingFailure() {
        let error = #expect(throws: NetworkError.self) {
            try JSONResponseDecoder(decoder: Fixtures.jsonDecoder).decode(TestCity.self, from: Data("{".utf8))
        }
        #expect(error?.caseName == "decoding")
    }

    @Test("Endpoints with an empty response ignore the body")
    func emptyResponse() throws {
        let decoder = JSONResponseDecoder(decoder: Fixtures.jsonDecoder)
        let endpoint = UploadEndpoint(payload: Data(), contentTypeOverride: nil)
        #expect(try endpoint.decode(Fixtures.response(status: 204, body: Data("not json".utf8)), using: decoder) == EmptyResponse())
    }

    @Test("Data responses get the raw body without JSON decoding")
    func rawData() throws {
        let decoder = JSONResponseDecoder(decoder: Fixtures.jsonDecoder)
        let body = Data([0xFF, 0xD8, 0xFF])
        #expect(try RawEndpoint().decode(Fixtures.response(status: 200, body: body), using: decoder) == body)
    }

    @Test("Header lookup ignores case")
    func headerLookup() {
        let response = Fixtures.response(status: 200, headers: ["Retry-After": "3"])
        #expect(response.value(forHeader: "retry-after") == "3")
        #expect(response.value(forHeader: "ETag") == nil)
    }
}
