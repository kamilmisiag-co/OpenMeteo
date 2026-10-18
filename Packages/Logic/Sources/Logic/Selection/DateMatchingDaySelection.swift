//
//  DateMatchingDaySelection.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public struct DateMatchingDaySelection: DaySelectionCarrying {
    public init() {}

    public func selection(_ day: Int?, carriedFrom previousDays: [DailyWeather], to days: [DailyWeather]) -> Int? {
        guard let day, previousDays.indices.contains(day) else { return nil }
        let date = previousDays[day].date
        return days.firstIndex { $0.date == date }
    }
}
