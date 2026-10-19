//
//  RankingList.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import DesignSystem
import Foundation
import Logic
import SwiftUI

struct RankingList: View {
    let presentation: RankingPresentation
    let openMeteo: URL?
    @Binding var selection: Int?
    let onShowWeek: () -> Void
    let onSelect: (Activity) -> Void

    var body: some View {
        List {
            if let banner = presentation.banner {
                Section {
                    StatusBanner(kind: banner.kind, message: banner.message)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }

            Section {
                ForecastStrip(title: presentation.stripTitle, days: presentation.stripDays, selection: $selection)
                    .listRowInsets(EdgeInsets(top: 12, leading: 8, bottom: 10, trailing: 8))
            }

            Section {
                if let topPick = presentation.topPick {
                    DisclosureButton {
                        onSelect(topPick.activity)
                    } label: {
                        TopPickCard(
                            title: topPick.title,
                            systemImage: topPick.systemImage,
                            reason: topPick.reason,
                            score: topPick.score,
                            dailyScores: topPick.dailyScores,
                            eyebrow: presentation.eyebrow,
                            dayInitials: presentation.dayInitials,
                            selectedDay: presentation.selectedDay,
                            bestDay: presentation.bestDay
                        )
                    }
                }
            } header: {
                SectionHeader {
                    Text(presentation.header)
                } trailing: {
                    if presentation.selectedDay != nil {
                        Button(.rankingShowWeek, action: onShowWeek)
                    }
                }
            }
            .headerProminence(.increased)

            Section {
                ForEach(presentation.others) { item in
                    DisclosureButton {
                        onSelect(item.activity)
                    } label: {
                        RankingRow(
                            rank: item.rank,
                            title: item.title,
                            systemImage: item.systemImage,
                            reason: item.reason,
                            score: item.score,
                            dailyScores: item.dailyScores,
                            selectedDay: presentation.selectedDay
                        )
                    }
                }
            } footer: {
                AttributionFooter(updated: presentation.updated, link: openMeteo)
                    .padding(.top, 12)
            }
        }
        .listStyle(.insetGrouped)
        .contentTransition(.numericText())
    }
}
