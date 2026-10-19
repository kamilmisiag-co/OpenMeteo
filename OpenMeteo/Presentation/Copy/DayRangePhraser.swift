//
//  DayRangePhraser.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic
import Utils

protocol DayRangeDescribing {
    func phrase(forDays indices: [Int], in days: [DailyWeather], format: any ForecastFormatting) -> String?
}

struct DayRangePhraser: DayRangeDescribing {
    func phrase(forDays indices: [Int], in days: [DailyWeather], format: any ForecastFormatting) -> String? {
        let selected = days.validIndices(among: indices)
        guard !selected.isEmpty else { return nil }
        guard selected.count < days.count else { return String(localized: .dayAllWeek) }
        let phrases = selected.consecutiveRuns().map { run in
            let first = format.weekday(days[run.lowerBound].date)
            guard run.lowerBound < run.upperBound else { return first }
            return String(localized: .dayRange(first, format.weekday(days[run.upperBound].date)))
        }
        return format.list(phrases)
    }
}
