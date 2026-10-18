//
//  RecentCitiesList.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import DesignSystem
import Foundation
import Logic
import SwiftUI

struct RecentCitiesList: View {
    let cities: [City]
    let onOpen: (City) -> Void
    let onRemove: (IndexSet) -> Void
    let onClear: () -> Void

    @State private var isConfirmingClear = false

    var body: some View {
        List {
            Section {
                ForEach(cities) { city in
                    DisclosureButton {
                        onOpen(city)
                    } label: {
                        CityRow(name: city.name, subtitle: city.subtitle, flag: city.flag)
                    }
                }
                .onDelete(perform: onRemove)
            } header: {
                SectionHeader {
                    Text(.searchRecentHeader)
                } trailing: {
                    Button(.searchRecentClear) {
                        isConfirmingClear = true
                    }
                    .confirmationDialog(.searchRecentClearConfirmTitle, isPresented: $isConfirmingClear, titleVisibility: .visible) {
                        Button(.searchRecentClearConfirmAction, role: .destructive) {
                            withAnimation { onClear() }
                        }
                    }
                }
            }
            .headerProminence(.increased)
        }
        .listStyle(.insetGrouped)
    }
}
