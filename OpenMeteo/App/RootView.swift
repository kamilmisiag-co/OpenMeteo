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
        NavigationStack {
            SearchScreen(
                viewModel: session.search,
                dayCount: session.dayCount,
                geoNames: session.links.geoNames,
                onOpen: session.open
            )
        }
    }
}

#if DEBUG
#Preview("Root") {
    RootView(session: PreviewAppFactory(recents: PreviewCities.recents).makeSession())
}
#endif
