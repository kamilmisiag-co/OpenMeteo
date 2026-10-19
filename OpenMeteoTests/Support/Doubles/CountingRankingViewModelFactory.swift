//
//  CountingRankingViewModelFactory.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic
@testable import OpenMeteo

@MainActor
final class CountingRankingViewModelFactory: RankingViewModelMaking {
    private let dependencies: RankingViewModel.Dependencies
    private(set) var madeCities: [City] = []

    init(dependencies: RankingViewModel.Dependencies = ViewModelFixtures.rankingDependencies()) {
        self.dependencies = dependencies
    }

    func makeRankingViewModel(for city: City) -> RankingViewModel {
        madeCities.append(city)
        return RankingViewModel(city: city, dependencies: dependencies)
    }
}
