//
//  RankingScreen.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Accessibility
import Logic
import SwiftUI

struct RankingScreen: View {
    let viewModel: RankingViewModel
    let links: AttributionLinks

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let presentation = viewModel.presentation
        let shown = presentation ?? viewModel.placeholder
        content(presentation)
            .navigationTitle(shown.title)
            .navigationSubtitle(shown.subtitle)
            .task {
                await viewModel.load()
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                viewModel.updateClock()
            }
            .onChange(of: presentation?.banner) { _, banner in
                guard let banner else { return }
                AccessibilityNotification.Announcement(banner.message).post()
            }
    }

    @ViewBuilder
    private func content(_ presentation: RankingPresentation?) -> some View {
        if let failure = viewModel.failure {
            ForecastFailureView(failure: failure) {
                await viewModel.retry()
            }
        } else if let presentation {
            RankingList(
                presentation: presentation,
                openMeteo: links.openMeteo,
                selection: Binding(
                    get: { presentation.selectedDay },
                    set: { day in animated { viewModel.select(day: day) } }
                ),
                onShowWeek: { animated { viewModel.showWeek() } }
            )
            .refreshable {
                await viewModel.refresh()
            }
        } else {
            RankingList(
                presentation: viewModel.placeholder,
                openMeteo: links.openMeteo,
                selection: .constant(nil),
                onShowWeek: {}
            )
            .redacted(reason: .placeholder)
            .allowsHitTesting(false)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(.rankingLoading))
        }
    }

    private func animated(_ change: () -> Void) {
        withAnimation(reduceMotion ? nil : .default, change)
    }
}

#if DEBUG
#Preview("S2.1 Week") {
    RootView(session: PreviewAppFactory(path: [.ranking(PreviewCities.lisbon)]).makeSession())
}

#Preview("S2.1 Week · Dark") {
    RootView(session: PreviewAppFactory(path: [.ranking(PreviewCities.lisbon)]).makeSession())
        .preferredColorScheme(.dark)
}

#Preview("S2.1 Week · AX1") {
    RootView(session: PreviewAppFactory(path: [.ranking(PreviewCities.lisbon)]).makeSession())
        .dynamicTypeSize(.accessibility1)
}

#Preview("S2.1 Week · US units") {
    RootView(
        session: PreviewAppFactory(
            path: [.ranking(PreviewCities.lisbon)],
            locale: Locale(identifier: "en_US")
        ).makeSession()
    )
}

#Preview("S2.2 Day selected") {
    let session = PreviewAppFactory(path: [.ranking(PreviewCities.lisbon)]).makeSession()
    PreparedPreview {
        let viewModel = session.navigator.rankingViewModel(for: PreviewCities.lisbon)
        await viewModel.load()
        viewModel.select(day: 5)
    } content: {
        RootView(session: session)
    }
}

#Preview("S2.2 Today selected") {
    let session = PreviewAppFactory(path: [.ranking(PreviewCities.lisbon)]).makeSession()
    PreparedPreview {
        let viewModel = session.navigator.rankingViewModel(for: PreviewCities.lisbon)
        await viewModel.load()
        viewModel.select(day: 0)
    } content: {
        RootView(session: session)
    }
}

#Preview("S2.3 Loading") {
    RootView(
        session: PreviewAppFactory(
            path: [.ranking(PreviewCities.lisbon)],
            forecastLatency: .seconds(3600)
        ).makeSession()
    )
}

#Preview("S2.5 Stale") {
    RootView(session: PreviewAppFactory(path: [.ranking(PreviewCities.lisbon)], forecastMode: .stale).makeSession())
}

#Preview("S2.6 Offline") {
    RootView(session: PreviewAppFactory(path: [.ranking(PreviewCities.lisbon)], forecastMode: .offline).makeSession())
}

#Preview("S2.7 Error") {
    RootView(session: PreviewAppFactory(path: [.ranking(PreviewCities.lisbon)], forecastMode: .failure).makeSession())
}

#Preview("S2.7 Error · No upcoming days") {
    RootView(session: PreviewAppFactory(path: [.ranking(PreviewCities.lisbon)], forecastMode: .noUpcomingDays).makeSession())
}

#Preview("S2.9 Nothing scores well") {
    RootView(session: PreviewAppFactory(path: [.ranking(PreviewCities.bergen)]).makeSession())
}
#endif
