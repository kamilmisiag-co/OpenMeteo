//
//  LabelledDayCaptions.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic
@testable import OpenMeteo

@MainActor
final class LabelledDayCaptions: DayCaptioning {
    struct Call {
        let activity: Activity
        let weather: DailyWeather
        let assessment: DayAssessment?
        let format: any ForecastFormatting
    }

    private(set) var calls: [Call] = []

    func caption(for activity: Activity, weather: DailyWeather, assessment: DayAssessment?, format: any ForecastFormatting) -> String {
        calls.append(Call(activity: activity, weather: weather, assessment: assessment, format: format))
        return "caption \(activity.rawValue) high \(Int(weather.highCelsius)) \(describe(assessment))"
    }

    private func describe(_ assessment: DayAssessment?) -> String {
        guard let assessment else { return "unassessed" }
        guard let score = assessment.score else {
            return "blocked \(assessment.blocker?.rawValue ?? "unknown")"
        }
        return "scored \(score)"
    }
}
