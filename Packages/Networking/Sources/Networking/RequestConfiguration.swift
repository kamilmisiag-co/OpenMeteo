//
//  RequestConfiguration.swift
//  Networking
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation

public struct RequestConfiguration: Sendable {
    public let baseURL: URL
    public let defaultHeaders: [String: String]
    public let timeout: Duration
    public let cachePolicy: URLRequest.CachePolicy

    public init(baseURL: URL, defaultHeaders: [String: String], timeout: Duration, cachePolicy: URLRequest.CachePolicy) {
        self.baseURL = baseURL
        self.defaultHeaders = defaultHeaders
        self.timeout = timeout
        self.cachePolicy = cachePolicy
    }
}
