//
//  AppServices.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic
import Utils

struct AppServices {
    let forecasts: any ForecastProviding
    let citySearch: any CitySearching
    let queryNormalizer: any SearchQueryNormalizing
    let recents: any RecentCitiesManaging
    let dates: any DateProviding
    let sleeper: any Sleeping
    let fallbackTimeZone: TimeZone
    let dayCount: Int
}
