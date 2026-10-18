//
//  RankingPresenting.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic

protocol RankingPresenting {
    func presentation(of summary: RankingSummary, in forecast: CityForecast, freshness: Freshness, now: Date) -> RankingPresentation
    func placeholder(for city: City) -> RankingPresentation
}
