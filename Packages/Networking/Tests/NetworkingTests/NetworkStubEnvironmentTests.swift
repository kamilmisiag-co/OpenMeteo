//
//  NetworkStubEnvironmentTests.swift
//  NetworkingTests
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation
import NetworkingStubs
import Testing

@Suite("Network stub environment")
struct NetworkStubEnvironmentTests {
    private let environment = NetworkStubEnvironment(key: "TEST_STUBS", encoder: JSONEncoder(), decoder: JSONDecoder())
    private let stubs = [
        NetworkStub(
            matcher: StubRequestMatcher(method: .get, host: nil, path: "/v1/search", queryItems: ["name": "Lis"]),
            responses: [
                StubResponse(outcome: .response(statusCode: 200, headers: ["Content-Type": "application/json"], body: Data("[]".utf8)), delay: .milliseconds(150)),
                StubResponse(outcome: .failure(urlErrorCode: URLError.Code.notConnectedToInternet.rawValue), delay: .zero),
            ]
        ),
    ]

    @Test("Stubs survive the trip through launch environment strings")
    func roundTrip() throws {
        let values = try environment.environment(for: stubs)
        #expect(Array(values.keys) == ["TEST_STUBS"])
        #expect(try environment.stubs(from: values) == stubs)
    }

    @Test("No key means no stubs")
    func missingKey() throws {
        #expect(try environment.stubs(from: ["OTHER": "[]"]) == nil)
    }

    @Test("A malformed value is reported, not ignored")
    func malformed() {
        #expect(throws: DecodingError.self) {
            try environment.stubs(from: ["TEST_STUBS": "{"])
        }
    }
}
