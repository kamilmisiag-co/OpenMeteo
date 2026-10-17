//
//  ActivityScoring.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public protocol ActivityScoring: Sendable {
    var activity: Activity { get }

    func assess(_ days: [DailyWeather]) -> [DayAssessment]
}
