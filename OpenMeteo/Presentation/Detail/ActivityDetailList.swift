//
//  ActivityDetailList.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import DesignSystem
import Foundation
import SwiftUI

struct ActivityDetailList: View {
    let detail: ActivityDetail
    let openMeteo: URL
    let onShowHowScores: () -> Void

    @State private var selectedBarID: Int?

    var body: some View {
        List {
            BannerSection(banner: detail.banner)

            Section {
                ActivityDetailHeader(detail: detail)
                    .listRowBackground(Color.clear)
            }

            Section {
                if let emptyChart = detail.emptyChart {
                    ContentUnavailableView {
                        Label {
                            Text(emptyChart.title)
                        } icon: {
                            Image(systemName: emptyChart.systemImage)
                        }
                    }
                    .font(.subheadline)
                } else {
                    DailyScoreChart(bars: detail.bars, weekScore: detail.score, selection: $selectedBarID)
                        .padding(.vertical, 8)
                }
            } header: {
                SectionHeader {
                    Text(.detailChartHeader)
                }
            }

            Section {
                ForEach(detail.days) { day in
                    DayScoreRow(
                        label: day.label,
                        isBest: day.isBest,
                        symbolName: day.symbolName,
                        conditionTitle: day.conditionTitle,
                        high: day.high,
                        low: day.low,
                        score: day.score,
                        caption: day.caption
                    )
                }
            } header: {
                SectionHeader {
                    Text(.detailDaysHeader)
                }
            }
            .headerProminence(.increased)

            if !detail.factors.isEmpty {
                Section {
                    ForEach(detail.factors) { factor in
                        FactorRow(title: factor.title, summary: factor.summary, value: factor.value, helps: factor.helps)
                    }
                } header: {
                    SectionHeader {
                        Text(.detailFactorsHeader)
                    }
                }
            }

            Section {
                DisclosureButton(action: onShowHowScores) {
                    Text(.howScoresTitle)
                }
            } header: {
                Text(detail.scoringNote)
                    .font(.footnote)
                    .textCase(nil)
                    .padding(.bottom, 8)
            } footer: {
                AttributionFooter(link: openMeteo)
                    .padding(.top, 12)
            }
        }
        .listStyle(.insetGrouped)
        .onChange(of: detail.days.map(\.label)) {
            selectedBarID = nil
        }
    }
}
