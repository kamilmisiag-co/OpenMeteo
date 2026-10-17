//
//  MockForecastProvider.swift
//  LogicMocks
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic

public actor MockForecastProvider: ForecastProviding {
    public typealias Handler = @Sendable (City) async throws -> ForecastResult

    private let handler: Handler
    public private(set) var requestedCities: [City] = []

    public init(handler: @escaping Handler) {
        self.handler = handler
    }

    public func forecast(for city: City) async throws -> ForecastResult {
        requestedCities.append(city)
        return try await handler(city)
    }
}
