//
//  SessionAssembler.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic

struct SessionAssembler {
    func makeSession(services: AppServices) -> AppSession {
        AppSession(
            search: SearchViewModel(dependencies: searchDependencies(services: services)),
            links: AttributionLinks(
                openMeteo: URL(string: AppStandard.openMeteoURLString),
                licence: URL(string: AppStandard.licenceURLString),
                geoNames: URL(string: AppStandard.geoNamesURLString)
            ),
            dayCount: services.dayCount
        )
    }

    private func searchDependencies(services: AppServices) -> SearchViewModel.Dependencies {
        SearchViewModel.Dependencies(
            resolver: CitySearchFlow(
                search: services.citySearch,
                normalizer: services.queryNormalizer,
                sleeper: services.sleeper,
                debounce: StandardRules.searchDebounce,
                failures: ErrorSearchFailureClassifier()
            ),
            recents: services.recents,
            sleeper: services.sleeper,
            debounce: StandardRules.searchDebounce,
            progressDelay: AppStandard.searchProgressDelay
        )
    }
}
