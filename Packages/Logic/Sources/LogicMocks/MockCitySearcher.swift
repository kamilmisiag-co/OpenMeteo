//
//  MockCitySearcher.swift
//  LogicMocks
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic

public actor MockCitySearcher: CitySearching {
    public typealias Handler = @Sendable (String) async throws -> CitySearchResult

    private let handler: Handler
    public private(set) var queries: [String] = []

    public init(handler: @escaping Handler) {
        self.handler = handler
    }

    public func search(_ rawQuery: String) async throws -> CitySearchResult {
        queries.append(rawQuery)
        return try await handler(rawQuery)
    }
}
