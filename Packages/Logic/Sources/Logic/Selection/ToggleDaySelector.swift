//
//  ToggleDaySelector.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public struct ToggleDaySelector: DaySelecting {
    public init() {}

    public func selection(afterChoosing day: Int?, current: Int?, dayCount: Int) -> Int? {
        guard let day, day != current else { return nil }
        return validated(day, dayCount: dayCount) ?? validated(current, dayCount: dayCount)
    }

    private func validated(_ day: Int?, dayCount: Int) -> Int? {
        guard let day, day >= 0, day < dayCount else { return nil }
        return day
    }
}
