//
//  ForecastLoadOutcome.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public enum ForecastLoadOutcome: Hashable, Sendable {
    case loaded(ForecastResult)
    case failed(ServiceFailure)
}
