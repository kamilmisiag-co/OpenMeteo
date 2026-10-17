//
//  BlockingRule.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public protocol BlockingRule: Sendable {
    var kind: Factor.Kind { get }

    func blocks(day index: Int, in days: [DailyWeather]) -> Bool
}
