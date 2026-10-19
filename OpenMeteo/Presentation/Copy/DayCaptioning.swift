//
//  DayCaptioning.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic

protocol DayCaptioning {
    func caption(for activity: Activity, weather: DailyWeather, assessment: DayAssessment?, format: any ForecastFormatting) -> String
}
