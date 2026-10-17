//
//  DayWindowing.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation

public protocol DayWindowing: Sendable {
    var dayCount: Int { get }

    func upcomingDays(_ days: [DailyWeather], in city: City, now: Date) -> [DailyWeather]
}
