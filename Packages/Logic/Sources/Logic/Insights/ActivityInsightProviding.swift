//
//  ActivityInsightProviding.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public protocol ActivityInsightProviding: Sendable {
    func insight(for activity: Activity, in forecast: CityForecast) -> ActivityInsight?
}
