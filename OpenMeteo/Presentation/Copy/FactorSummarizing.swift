//
//  FactorSummarizing.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic

protocol FactorSummarizing {
    func summary(of factor: Factor, in outlook: ActivityOutlook, days: [DailyWeather], format: any ForecastFormatting) -> String
    func value(of kind: Factor.Kind, across days: [DailyWeather], format: any ForecastFormatting) -> String?
}
