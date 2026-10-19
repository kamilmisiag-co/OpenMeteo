//
//  RankingViewModelFactory.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic

protocol RankingViewModelMaking {
    func makeRankingViewModel(for city: City) -> RankingViewModel
}

struct RankingViewModelFactory: RankingViewModelMaking {
    private let dependencies: RankingViewModel.Dependencies

    init(dependencies: RankingViewModel.Dependencies) {
        self.dependencies = dependencies
    }

    func makeRankingViewModel(for city: City) -> RankingViewModel {
        RankingViewModel(city: city, dependencies: dependencies)
    }
}
