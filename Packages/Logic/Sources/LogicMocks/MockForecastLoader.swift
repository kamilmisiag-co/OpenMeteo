//
//  MockForecastLoader.swift
//  LogicMocks
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic

public actor MockForecastLoader: ForecastLoading {
    public typealias Handler = @Sendable (City) async -> ForecastLoadOutcome?

    private let handler: Handler
    public private(set) var requestedCities: [City] = []

    public init(handler: @escaping Handler) {
        self.handler = handler
    }

    public func load(_ city: City) async -> ForecastLoadOutcome? {
        requestedCities.append(city)
        return await handler(city)
    }
}
