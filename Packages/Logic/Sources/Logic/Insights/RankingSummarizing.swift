//
//  RankingSummarizing.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public protocol RankingSummarizing: Sendable {
    func summary(of forecast: CityForecast, onDay day: Int?) -> RankingSummary
}
