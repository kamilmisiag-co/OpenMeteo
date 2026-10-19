//
//  ToggleDaySelector.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Utils

public protocol DaySelecting: Sendable {
    func selection(afterChoosing day: Int?, current: Int?, dayCount: Int) -> Int?
}

public struct ToggleDaySelector: DaySelecting {
    public init() {}

    public func selection(afterChoosing day: Int?, current: Int?, dayCount: Int) -> Int? {
        guard let day, day != current else { return nil }
        let days = 0..<max(dayCount, 0)
        return days.validIndex(day) ?? days.validIndex(current)
    }
}
