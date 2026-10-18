//
//  ForecastLoading.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public protocol ForecastLoading: Sendable {
    func load(_ city: City) async -> ForecastLoadOutcome?
}
