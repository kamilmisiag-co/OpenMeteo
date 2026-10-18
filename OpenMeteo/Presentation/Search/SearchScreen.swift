//
//  SearchScreen.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic
import SwiftUI

struct SearchScreen: View {
    @Bindable var viewModel: SearchViewModel
    let dayCount: Int
    let geoNames: URL?
    let onOpen: (City) -> Void

    var body: some View {
        content
            .navigationTitle(.searchTitle)
            .searchable(text: $viewModel.query, prompt: Text(.searchPrompt))
            .autocorrectionDisabled()
            .onChange(of: viewModel.query) {
                viewModel.queryDidChange()
            }
            .task(id: viewModel.request) {
                await viewModel.search()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            if viewModel.recents.isEmpty {
                SearchEmptyView(dayCount: dayCount)
            } else {
                RecentCitiesList(
                    cities: viewModel.recents,
                    onOpen: onOpen,
                    onRemove: viewModel.removeRecents(at:),
                    onClear: viewModel.clearRecents
                )
            }
        case .searching(let query, let cities), .results(let query, let cities):
            if cities.isEmpty {
                SearchProgressView(isVisible: viewModel.isShowingProgress)
            } else {
                SearchResultsList(
                    cities: cities,
                    highlight: query,
                    isSearching: viewModel.isShowingProgress,
                    geoNames: geoNames,
                    onOpen: onOpen
                )
            }
        case .noResults(let query):
            ContentUnavailableView.search(text: query)
        case .failed(_, let failure):
            SearchUnavailableView(failure: failure, onRetry: viewModel.retry)
        }
    }
}

#if DEBUG
#Preview("S1.1 First launch") {
    RootView(session: PreviewAppFactory().makeSession())
}

#Preview("S1.2 Recents") {
    RootView(session: PreviewAppFactory(recents: PreviewCities.recents).makeSession())
}

#Preview("S1.2 Recents · Dark") {
    RootView(session: PreviewAppFactory(recents: PreviewCities.recents).makeSession())
        .preferredColorScheme(.dark)
}

#Preview("S1.2 Recents · AX1") {
    RootView(session: PreviewAppFactory(recents: PreviewCities.recents).makeSession())
        .dynamicTypeSize(.accessibility1)
}

#Preview("S1.5 Searching") {
    RootView(session: PreviewAppFactory(query: "Lis", searchLatency: .seconds(3600)).makeSession())
}

#Preview("S1.5 Searching · Previous results") {
    let session = PreviewAppFactory(query: "Lis", searchLatency: .zero, searchLatencies: ["Lisb": .seconds(3600)]).makeSession()
    PreparedPreview {
        await session.search.search()
        session.search.query = "Lisb"
        session.search.queryDidChange()
    } content: {
        RootView(session: session)
    }
}

#Preview("S1.6 Results") {
    RootView(session: PreviewAppFactory(query: "Lis", searchLatency: .zero).makeSession())
}

#Preview("S1.7 No results") {
    RootView(session: PreviewAppFactory(query: "Lisx", searchLatency: .zero).makeSession())
}

#Preview("S1.8 Search unavailable") {
    RootView(session: PreviewAppFactory(query: "Lis", searchLatency: .zero, searchFailure: URLError(.notConnectedToInternet)).makeSession())
}

#Preview("S1.8 Search unavailable · Service") {
    RootView(session: PreviewAppFactory(query: "Lis", searchLatency: .zero, searchFailure: URLError(.badServerResponse)).makeSession())
}
#endif
