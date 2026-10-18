//
//  ForecastStateUpdating.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public protocol ForecastStateUpdating: Sendable {
    func state(_ current: ForecastState, applying outcome: ForecastLoadOutcome, for city: City) -> ForecastState
}
