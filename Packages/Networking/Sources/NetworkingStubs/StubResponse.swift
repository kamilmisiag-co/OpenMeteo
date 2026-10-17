//
//  StubResponse.swift
//  NetworkingStubs
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation

public enum StubOutcome: Codable, Hashable, Sendable {
    case response(statusCode: Int, headers: [String: String], body: Data)
    case failure(urlErrorCode: Int)
}

public struct StubResponse: Codable, Hashable, Sendable {
    public let outcome: StubOutcome
    public let delay: Duration

    public init(outcome: StubOutcome, delay: Duration) {
        self.outcome = outcome
        self.delay = delay
    }
}
