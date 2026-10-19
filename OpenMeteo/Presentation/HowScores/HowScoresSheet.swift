//
//  HowScoresSheet.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import DesignSystem
import Logic
import SwiftUI

struct HowScoresSheet: View {
    let dayCount: Int
    let links: AttributionLinks

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(.howScoresIntro(dayCount))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section {
                    ForEach(Rating.allCases, id: \.self) { rating in
                        RatingLegendRow(rating: rating)
                    }
                } header: {
                    Text(.howScoresRatingsHeader)
                }

                Section {
                    ForEach(Activity.allCases) { activity in
                        ActivityCriteriaRow(activity: activity)
                    }
                } header: {
                    Text(.howScoresActivitiesHeader)
                }

                Section {
                    Text(.howScoresAssumptionsTimeZone)
                    Text(.howScoresAssumptionsSurf)
                    Text(.howScoresAssumptionsUnits)
                } header: {
                    Text(.howScoresAssumptionsHeader)
                }

                Section {
                    Link(.howScoresDataOpenMeteo, destination: links.openMeteo)
                    Link(.howScoresDataLicence, destination: links.licence)
                    Link(.howScoresDataGeoNames, destination: links.geoNames)
                } header: {
                    Text(.howScoresDataHeader)
                } footer: {
                    Text(.howScoresDataDerived)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(.howScoresTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(.howScoresDone, systemImage: "checkmark") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#if DEBUG
#Preview("S4 How scores work") {
    let session = PreviewAppFactory().makeSession()
    Color.clear
        .sheet(isPresented: .constant(true)) {
            HowScoresSheet(dayCount: session.dayCount, links: session.links)
        }
}

#Preview("S4 How scores work · Large") {
    let session = PreviewAppFactory().makeSession()
    HowScoresSheet(dayCount: session.dayCount, links: session.links)
}
#endif
