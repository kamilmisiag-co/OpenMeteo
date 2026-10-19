//
//  AppNavigator.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic
import Observation

@Observable
final class AppNavigator {
    var path: [AppRoute] = [] {
        didSet { releaseRankingViewModelsOutsidePath() }
    }

    @ObservationIgnored private let rankings: any RankingViewModelMaking
    @ObservationIgnored private var rankingViewModels: [City.ID: RankingViewModel] = [:]

    init(rankings: any RankingViewModelMaking) {
        self.rankings = rankings
    }

    @discardableResult
    func showRanking(for city: City) -> Bool {
        push(.ranking(city))
    }

    @discardableResult
    func showDetail(of activity: Activity, in city: City) -> Bool {
        push(.detail(city, activity))
    }

    func rankingViewModel(for city: City) -> RankingViewModel {
        if let viewModel = rankingViewModels[city.id] {
            return viewModel
        }
        let viewModel = rankings.makeRankingViewModel(for: city)
        rankingViewModels[city.id] = viewModel
        return viewModel
    }

    private func push(_ route: AppRoute) -> Bool {
        guard path.last != route else { return false }
        path.append(route)
        return true
    }

    private func releaseRankingViewModelsOutsidePath() {
        let shownCityIDs = Set(path.map { Self.city(of: $0).id })
        guard rankingViewModels.keys.contains(where: { !shownCityIDs.contains($0) }) else { return }
        rankingViewModels = rankingViewModels.filter { shownCityIDs.contains($0.key) }
    }

    private static func city(of route: AppRoute) -> City {
        switch route {
        case .ranking(let city), .detail(let city, _): city
        }
    }
}
