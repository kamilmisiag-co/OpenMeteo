//
//  ActivityDetailScreen.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic
import SwiftUI

struct ActivityDetailScreen: View {
    let viewModel: RankingViewModel
    let activity: Activity
    let links: AttributionLinks

    @State private var isShowingHowScores = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        let detail = viewModel.detail(for: activity)
        content(detail)
            .navigationTitle(activity.title)
            .navigationSubtitle(detail?.subtitle ?? viewModel.city.name)
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

    @ViewBuilder
    private func content(_ detail: ActivityDetail?) -> some View {
        if let detail {
            ActivityDetailList(detail: detail, openMeteo: links.openMeteo) {
                isShowingHowScores = true
            }
            .refreshable {
                await viewModel.refresh()
            }
        } else if let failure = viewModel.failure {
            ForecastFailureView(failure: failure) {
                await viewModel.retry()
            }
        } else if viewModel.isLoading {
            ProgressView {
                Text(.rankingLoading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ContentUnavailableView {
                Label {
                    Text(.detailUnavailableTitle)
                } icon: {
                    Image(systemName: activity.systemImage)
                }
            }
        }
    }
}

#if DEBUG
#Preview("S3.1 Surfing") {
    RootView(
        session: PreviewAppFactory(
            path: [.ranking(PreviewCities.lisbon), .detail(PreviewCities.lisbon, .surfing)]
        ).makeSession()
    )
}

#Preview("S3.1 Surfing · Dark") {
    RootView(
        session: PreviewAppFactory(
            path: [.ranking(PreviewCities.lisbon), .detail(PreviewCities.lisbon, .surfing)]
        ).makeSession()
    )
    .preferredColorScheme(.dark)
}

#Preview("S3.1 Surfing · AX1") {
    RootView(
        session: PreviewAppFactory(
            path: [.ranking(PreviewCities.lisbon), .detail(PreviewCities.lisbon, .surfing)]
        ).makeSession()
    )
    .dynamicTypeSize(.accessibility1)
}

#Preview("S3.1 Surfing · US units") {
    RootView(
        session: PreviewAppFactory(
            path: [.ranking(PreviewCities.lisbon), .detail(PreviewCities.lisbon, .surfing)],
            locale: Locale(identifier: "en_US")
        ).makeSession()
    )
}

#Preview("S3.3 Indoor sightseeing") {
    RootView(
        session: PreviewAppFactory(
            path: [.ranking(PreviewCities.lisbon), .detail(PreviewCities.lisbon, .indoorSightseeing)]
        ).makeSession()
    )
}

#Preview("S3.4 Skiing") {
    RootView(
        session: PreviewAppFactory(
            path: [.ranking(PreviewCities.lisbon), .detail(PreviewCities.lisbon, .skiing)]
        ).makeSession()
    )
}

#Preview("S3.5 Offline") {
    RootView(
        session: PreviewAppFactory(
            path: [.ranking(PreviewCities.lisbon), .detail(PreviewCities.lisbon, .surfing)],
            forecastMode: .offline
        ).makeSession()
    )
}
#endif
