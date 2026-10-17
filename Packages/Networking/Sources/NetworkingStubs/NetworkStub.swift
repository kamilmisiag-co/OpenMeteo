//
//  NetworkStub.swift
//  NetworkingStubs
//
//  Created by Kamil Misiag on 16/10/2026.
//

public struct NetworkStub: Codable, Hashable, Sendable {
    public let matcher: StubRequestMatcher
    public let responses: [StubResponse]

    public init(matcher: StubRequestMatcher, responses: [StubResponse]) {
        self.matcher = matcher
        self.responses = responses
    }
}
