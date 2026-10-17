//
//  UpcomingDaysWindow.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Utils

public struct UpcomingDaysWindow: DayWindowing {
    public let dayCount: Int
    private let fallbackTimeZone: TimeZone

    public init(dayCount: Int, fallbackTimeZone: TimeZone) {
        self.dayCount = dayCount
        self.fallbackTimeZone = fallbackTimeZone
    }

    public func upcomingDays(_ days: [DailyWeather], in city: City, now: Date) -> [DailyWeather] {
        let calendar = Calendar.gregorian(timeZone: city.timeZone ?? fallbackTimeZone)
        let today = calendar.startOfDay(for: now)
        let upcoming = days
            .filter { calendar.startOfDay(for: $0.date) >= today }
            .sorted { $0.date < $1.date }
            .uniqued { calendar.startOfDay(for: $0.date) }
        return Array(upcoming.prefix(max(dayCount, 0)))
    }
}
