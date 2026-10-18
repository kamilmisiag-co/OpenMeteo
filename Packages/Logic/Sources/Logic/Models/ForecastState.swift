//
//  ForecastState.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public enum ForecastState: Hashable, Sendable {
    case loading
    case loaded(LoadedForecast)
    case failed(ServiceFailure)

    public var loadedForecast: LoadedForecast? {
        guard case .loaded(let forecast) = self else { return nil }
        return forecast
    }
}
