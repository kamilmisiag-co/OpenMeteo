//
//  HTTPResponse.swift
//  Networking
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation

public struct HTTPResponse: Hashable, Sendable {
    public let statusCode: Int
    public let headers: [String: String]
    public let body: Data
    public let url: URL?

    public init(statusCode: Int, headers: [String: String], body: Data, url: URL?) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
        self.url = url
    }

    public func value(forHeader field: String) -> String? {
        headers.first { $0.key.caseInsensitiveCompare(field) == .orderedSame }?.value
    }
}
