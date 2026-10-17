//
//  MockCityGeocoder.swift
//  LogicMocks
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic

public actor MockCityGeocoder: CityGeocoding {
    public typealias Handler = @Sendable (String) async throws -> [City]

    private let handler: Handler
    public private(set) var requestedNames: [String] = []

    public init(handler: @escaping Handler) {
        self.handler = handler
    }

    public func cities(named name: String) async throws -> [City] {
        requestedNames.append(name)
        return try await handler(name)
    }
}
