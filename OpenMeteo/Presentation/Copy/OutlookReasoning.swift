//
//  OutlookReasoning.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic

protocol OutlookReasoning {
    func reason(for outlook: ActivityOutlook, days: [DailyWeather], format: any ForecastFormatting) -> String
}
