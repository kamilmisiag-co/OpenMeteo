//
//  ConditionBlocker.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Utils

public struct ConditionBlocker: BlockingRule {
    public let kind: Factor.Kind
    private let conditions: Set<WeatherCondition>

    public init(kind: Factor.Kind, conditions: Set<WeatherCondition>) {
        self.kind = kind
        self.conditions = conditions
    }

    public func blocks(day index: Int, in days: [DailyWeather]) -> Bool {
        guard let day = days.element(at: index) else { return false }
        return conditions.contains(day.condition)
    }
}
