//
//  AppSession.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic
import Observation

@Observable
final class AppSession {
    let search: SearchViewModel
    let links: AttributionLinks
    let dayCount: Int

    init(search: SearchViewModel, links: AttributionLinks, dayCount: Int) {
        self.search = search
        self.links = links
        self.dayCount = dayCount
    }

    func open(_ city: City) {
        search.open(city)
    }
}
