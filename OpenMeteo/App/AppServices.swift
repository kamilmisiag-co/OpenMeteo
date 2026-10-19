//
//  AppServices.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic
import Utils

struct AppServices {
    let citySearch: any CitySearching
    let queryNormalizer: any SearchQueryNormalizing
    let recents: any RecentCitiesManaging
    let sleeper: any Sleeping
    let dayCount: Int
}
