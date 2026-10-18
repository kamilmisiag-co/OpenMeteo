//
//  SearchResultsList.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import DesignSystem
import Foundation
import Logic
import SwiftUI

struct SearchResultsList: View {
    let cities: [City]
    let highlight: String
    let isSearching: Bool
    let geoNames: URL?
    let onOpen: (City) -> Void

    var body: some View {
        List {
            Section {
                ForEach(cities) { city in
                    DisclosureButton {
                        onOpen(city)
                    } label: {
                        CityRow(name: city.name, subtitle: city.subtitle, flag: city.flag, highlight: highlight)
                    }
                }
            } header: {
                SectionHeader {
                    Text(.searchResultsHeader)
                } trailing: {
                    if isSearching {
                        ProgressView()
                            .accessibilityLabel(Text(.searchSearching))
                    }
                }
            } footer: {
                attribution
            }
            .headerProminence(.increased)
        }
        .listStyle(.insetGrouped)
    }

    @ViewBuilder
    private var attribution: some View {
        if let geoNames {
            Link(destination: geoNames) {
                Text(.searchResultsAttribution)
            }
        } else {
            Text(.searchResultsAttribution)
        }
    }
}
