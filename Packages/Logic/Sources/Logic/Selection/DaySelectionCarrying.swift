//
//  DaySelectionCarrying.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public protocol DaySelectionCarrying: Sendable {
    func selection(_ day: Int?, carriedFrom previousDays: [DailyWeather], to days: [DailyWeather]) -> Int?
}
