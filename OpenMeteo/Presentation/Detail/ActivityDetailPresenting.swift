//
//  ActivityDetailPresenting.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic

protocol ActivityDetailPresenting {
    func detail(for insight: ActivityInsight, in forecast: CityForecast, freshness: Freshness, now: Date) -> ActivityDetail
}
