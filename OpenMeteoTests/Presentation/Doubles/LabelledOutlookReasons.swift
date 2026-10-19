//
//  LabelledOutlookReasons.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic
@testable import OpenMeteo

@MainActor
final class LabelledOutlookReasons: OutlookReasoning {
    struct Call {
        let outlook: ActivityOutlook
        let days: [DailyWeather]
        let format: any ForecastFormatting
    }

    private(set) var calls: [Call] = []

    func reason(for outlook: ActivityOutlook, days: [DailyWeather], format: any ForecastFormatting) -> String {
        calls.append(Call(outlook: outlook, days: days, format: format))
        return "reason \(outlook.activity.rawValue) over \(days.count) days"
    }
}
