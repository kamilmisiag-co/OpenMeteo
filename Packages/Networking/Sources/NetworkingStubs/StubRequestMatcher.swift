//
//  StubRequestMatcher.swift
//  NetworkingStubs
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation
import Networking

public struct StubRequestMatcher: Codable, Hashable, Sendable {
    public let method: HTTPMethod?
    public let host: String?
    public let path: String
    public let queryItems: [String: String]

    public init(method: HTTPMethod?, host: String?, path: String, queryItems: [String: String]) {
        self.method = method
        self.host = host
        self.path = path
        self.queryItems = queryItems
    }

    public func matches(_ request: URLRequest) -> Bool {
        guard let url = request.url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return false }
        if let method, request.httpMethod != method.rawValue { return false }
        if let host, components.host?.caseInsensitiveCompare(host) != .orderedSame { return false }
        guard components.path == path else { return false }
        let actual = Dictionary(
            (components.queryItems ?? []).map { ($0.name, $0.value ?? "") },
            uniquingKeysWith: { first, _ in first }
        )
        return queryItems.allSatisfy { actual[$0.key] == $0.value }
    }
}
