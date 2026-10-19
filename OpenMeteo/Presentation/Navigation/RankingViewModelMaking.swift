//
//  RankingViewModelMaking.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic

protocol RankingViewModelMaking {
    func makeRankingViewModel(for city: City) -> RankingViewModel
}
