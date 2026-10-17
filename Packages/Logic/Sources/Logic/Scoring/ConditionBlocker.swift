//
//  ConditionBlocker.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public struct ConditionBlocker: BlockingRule {
    public let kind: Factor.Kind
    private let conditions: Set<WeatherCondition>

    public init(kind: Factor.Kind, conditions: Set<WeatherCondition>) {
        self.kind = kind
        self.conditions = conditions
    }

    public func blocks(day index: Int, in days: [DailyWeather]) -> Bool {
        days.indices.contains(index) && conditions.contains(days[index].condition)
    }
}
