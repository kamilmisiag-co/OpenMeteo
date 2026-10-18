//
//  SampleForecastProvider.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

#if DEBUG
import Foundation
import Logic
import Utils

nonisolated struct SampleForecastProvider: ForecastProviding {
    nonisolated enum Mode: Hashable, Sendable {
        case live
        case stale
        case offline
        case failure
        case noUpcomingDays
    }

    private static let staleAge: TimeInterval = 4 * 60 * 60
    private static let offlineAge: TimeInterval = 15 * 60 * 60

    private let mode: Mode
    private let latency: Duration
    private let fallbackTimeZone: TimeZone
    private let dates: any DateProviding
    private let sleeper: any Sleeping

    init(mode: Mode = .live, latency: Duration = .zero, fallbackTimeZone: TimeZone, dates: any DateProviding, sleeper: any Sleeping) {
        self.mode = mode
        self.latency = latency
        self.fallbackTimeZone = fallbackTimeZone
        self.dates = dates
        self.sleeper = sleeper
    }

    func forecast(for city: City) async throws -> ForecastResult {
        if latency > .zero {
            try await sleeper.sleep(for: latency)
        }
        let now = dates.now()
        switch mode {
        case .live:
            return result(for: city, now: now, fetchedAt: now, origin: .live)
        case .stale:
            return result(for: city, now: now, fetchedAt: now.addingTimeInterval(-Self.staleAge), origin: .live)
        case .offline:
            return result(for: city, now: now, fetchedAt: now.addingTimeInterval(-Self.offlineAge), origin: .cache)
        case .failure:
            throw URLError(.notConnectedToInternet)
        case .noUpcomingDays:
            throw ForecastError.noUpcomingDays
        }
    }

    private func result(for city: City, now: Date, fetchedAt: Date, origin: ForecastResult.Origin) -> ForecastResult {
        ForecastResult(
            forecast: PreviewForecasts.forecast(for: city, startingAt: now, fetchedAt: fetchedAt, fallbackTimeZone: fallbackTimeZone),
            origin: origin
        )
    }
}
#endif
