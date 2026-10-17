//
//  ForecastProviding.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public protocol ForecastProviding: Sendable {
    func forecast(for city: City) async throws -> ForecastResult
}
