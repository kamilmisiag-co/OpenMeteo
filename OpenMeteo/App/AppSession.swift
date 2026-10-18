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
    let navigator: AppNavigator
    let links: AttributionLinks
    let dayCount: Int

    init(search: SearchViewModel, navigator: AppNavigator, links: AttributionLinks, dayCount: Int) {
        self.search = search
        self.navigator = navigator
        self.links = links
        self.dayCount = dayCount
    }

    func open(_ city: City) {
        guard navigator.showRanking(for: city) else { return }
        search.open(city)
    }
}
