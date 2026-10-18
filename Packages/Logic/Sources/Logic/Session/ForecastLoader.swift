//
//  ForecastLoader.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public struct ForecastLoader: ForecastLoading {
    private let forecasts: any ForecastProviding
    private let failures: any FailureClassifying

    public init(forecasts: any ForecastProviding, failures: any FailureClassifying) {
        self.forecasts = forecasts
        self.failures = failures
    }

    public func load(_ city: City) async -> ForecastLoadOutcome? {
        do {
            let result = try await forecasts.forecast(for: city)
            return Task.isCancelled ? nil : .loaded(result)
        } catch {
            return Task.isCancelled ? nil : .failed(failures.failure(for: error))
        }
    }
}
