//
//  DayRangeDescribing.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic

protocol DayRangeDescribing {
    func phrase(forDays indices: [Int], in days: [DailyWeather], format: any ForecastFormatting) -> String?
}
