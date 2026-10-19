//
//  RootView.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic
import SwiftUI

struct RootView: View {
    let session: AppSession

    var body: some View {
        @Bindable var navigator = session.navigator
        NavigationStack(path: $navigator.path) {
            SearchScreen(
                viewModel: session.search,
                dayCount: session.dayCount,
                geoNames: session.links.geoNames,
                onOpen: session.open
            )
            .navigationDestination(for: AppRoute.self) { route in
                destination(for: route)
            }
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .ranking(let city):
            RankingScreen(
                viewModel: session.navigator.rankingViewModel(for: city),
                links: session.links
            )
        }
    }
}

#if DEBUG
#Preview("Root") {
    RootView(session: PreviewAppFactory(recents: PreviewCities.recents).makeSession())
}
#endif
