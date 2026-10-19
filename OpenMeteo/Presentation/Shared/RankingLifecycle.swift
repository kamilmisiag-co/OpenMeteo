//
//  RankingLifecycle.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 19/10/2026.
//

import SwiftUI

struct RankingLifecycle: ViewModifier {
    let viewModel: RankingViewModel
    let links: AttributionLinks
    @Binding var isShowingHowScores: Bool

    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isShowingHowScores) {
                HowScoresSheet(dayCount: viewModel.dayCount, links: links)
            }
            .task {
                await viewModel.load()
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                viewModel.updateClock()
            }
    }
}

extension View {
    func rankingLifecycle(of viewModel: RankingViewModel, links: AttributionLinks, isShowingHowScores: Binding<Bool>) -> some View {
        modifier(RankingLifecycle(viewModel: viewModel, links: links, isShowingHowScores: isShowingHowScores))
    }
}
