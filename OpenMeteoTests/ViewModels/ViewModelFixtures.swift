//
//  ViewModelFixtures.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic
@testable import OpenMeteo

@MainActor
enum ViewModelFixtures {
    static let debounce = Duration.milliseconds(250)
    static let progressDelay = Duration.milliseconds(300)

    static func searchDependencies(
        resolver: SearchResolverDouble = SearchResolverDouble(immediate: { _, _ in nil }, resolution: { _ in nil }),
        recents: ScriptedRecentCitiesManager = ScriptedRecentCitiesManager(),
        sleeper: ControlledSleeper = ControlledSleeper()
    ) -> SearchViewModel.Dependencies {
        SearchViewModel.Dependencies(
            resolver: resolver,
            recents: recents,
            sleeper: sleeper,
            debounce: debounce,
            progressDelay: progressDelay
        )
    }
}
