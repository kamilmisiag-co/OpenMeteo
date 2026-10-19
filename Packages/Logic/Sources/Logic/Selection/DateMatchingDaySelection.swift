//
//  DateMatchingDaySelection.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Utils

public protocol DaySelectionCarrying: Sendable {
    func selection(_ day: Int?, carriedFrom previousDays: [DailyWeather], to days: [DailyWeather]) -> Int?
}

public struct DateMatchingDaySelection: DaySelectionCarrying {
    public init() {}

    public func selection(_ day: Int?, carriedFrom previousDays: [DailyWeather], to days: [DailyWeather]) -> Int? {
        guard let day, let date = previousDays.element(at: day)?.date else { return nil }
        return days.firstIndex { $0.date == date }
    }
}
