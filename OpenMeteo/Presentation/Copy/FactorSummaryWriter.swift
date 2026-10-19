//
//  FactorSummaryWriter.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic
import Utils

protocol FactorSummarizing {
    func summary(of factor: Factor, in outlook: ActivityOutlook, days: [DailyWeather], format: any ForecastFormatting) -> String
    func value(of kind: Factor.Kind, across days: [DailyWeather], format: any ForecastFormatting) -> String?
}

struct FactorSummaryWriter: FactorSummarizing {
    private let dayRanges: any DayRangeDescribing

    init(dayRanges: any DayRangeDescribing) {
        self.dayRanges = dayRanges
    }

    func summary(
        of factor: Factor,
        in outlook: ActivityOutlook,
        days: [DailyWeather],
        format: any ForecastFormatting
    ) -> String {
        let indices = measuredIndices(of: factor, in: days)
        let measured = indices.map { days[$0] }
        let phrase = dayRanges.phrase(forDays: indices, in: days, format: format) ?? String(localized: .dayAllWeek)
        switch factor.kind {
        case .wind:
            let speed = measured.map(\.windSpeedKmh).max().map(format.speed) ?? format.noValue
            let gusts = measured.map(\.windGustsKmh).max().map(format.speed) ?? format.noValue
            return String(localized: .factorWindSummary(speed, gusts, phrase))
        case .rain:
            let chance = value(of: .rain, across: measured, format: format) ?? format.noValue
            return String(localized: .factorRainSummary(chance, phrase))
        case .temperature:
            let highs = measured.map(\.highCelsius).minAndMax().map { format.temperatureRange($0.min, $0.max) } ?? format.noValue
            return String(localized: .factorTemperatureSummary(highs, phrase))
        case .snowfall:
            let isBlocked = !indices.isEmpty && indices.allSatisfy { outlook.days.element(at: $0)?.blocker == .snowfall }
            guard !isBlocked else { return String(localized: .factorSnowfallSummaryBlocked(phrase)) }
            return String(localized: .factorSnowfallSummary(format.snowfall(measured.sum(of: \.snowfallCm)), phrase))
        case .thunderstorm:
            return String(localized: .factorThunderstormSummary(phrase))
        }
    }

    func value(of kind: Factor.Kind, across days: [DailyWeather], format: any ForecastFormatting) -> String? {
        switch kind {
        case .wind:
            days.map(\.windSpeedKmh).minAndMax().map { format.speedRange($0.min, $0.max) }
        case .rain:
            days.compactMap(\.precipitationProbability).minAndMax().map { format.percentRange($0.min, $0.max) }
        case .temperature:
            temperatureBounds(of: days).map { format.temperatureRange($0.lower, $0.upper) }
        case .snowfall:
            days.isEmpty ? nil : format.snowfall(days.sum(of: \.snowfallCm))
        case .thunderstorm:
            nil
        }
    }

    private func measuredIndices(of factor: Factor, in days: [DailyWeather]) -> [Int] {
        let indices = days.validIndices(among: factor.days)
        return indices.isEmpty ? Array(days.indices) : indices
    }

    private func temperatureBounds(of days: [DailyWeather]) -> (lower: Double, upper: Double)? {
        guard let lower = days.map(\.lowCelsius).min(), let upper = days.map(\.highCelsius).max() else { return nil }
        return (lower, upper)
    }
}
