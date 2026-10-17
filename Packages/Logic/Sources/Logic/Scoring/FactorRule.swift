//
//  FactorRule.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public protocol FactorRule: Sendable {
    var kind: Factor.Kind { get }
    var weight: Double { get }

    func suitability(ofDay index: Int, in days: [DailyWeather]) -> Double?
}
