//
//  DailyScoreChart.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Charts
import DesignSystem
import Logic
import SwiftUI

struct DailyScoreChart: View {
    let bars: [ActivityDetailBar]
    let weekScore: Int?
    @Binding var selection: Int?

    @ScaledMetric(relativeTo: .body) private var height: CGFloat = 200
    @ScaledMetric(relativeTo: .caption) private var legendLineWidth: CGFloat = 20

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            chart
            if let weekScore {
                weekLegend(weekScore)
            }
        }
    }

    private var chart: some View {
        Chart {
            ForEach(bars) { bar in
                BarMark(
                    x: .value(.detailChartDay, key(of: bar)),
                    y: .value(.detailChartScore, bar.score ?? 0),
                    width: .ratio(0.55)
                )
                .foregroundStyle(Rating(score: bar.score).color)
                .cornerRadius(5)
                .opacity(isDimmed(bar) ? 0.35 : 1)
                .annotation(position: .top, spacing: 4) {
                    if bar.isBest, selectedBar == nil {
                        Text(.detailChartBest)
                            .font(.caption.weight(.semibold))
                    }
                }
                .accessibilityLabel(bar.accessibilityLabel)
            }

            if let weekScore {
                RuleMark(y: .value(.detailChartWeek, weekScore))
                    .lineStyle(weekRuleStyle)
                    .foregroundStyle(Color.secondary)
                    .accessibilityHidden(true)
            }

            if let selectedBar {
                RuleMark(x: .value(.detailChartDay, key(of: selectedBar)))
                    .foregroundStyle(Color.secondary.opacity(0.35))
                    .annotation(
                        position: .top,
                        spacing: 0,
                        overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                    ) {
                        DailyScoreCallout(bar: selectedBar)
                    }
                    .accessibilityHidden(true)
            }
        }
        .chartYScale(domain: 0...100)
        .chartYAxis {
            AxisMarks(position: .trailing, values: [0, 50, 100])
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let bar = bar(forKey: value.as(String.self)) {
                        Text(bar.label)
                    }
                }
            }
        }
        .chartXSelection(value: selectedKey)
        .frame(height: height)
    }

    private var weekRuleStyle: StrokeStyle {
        StrokeStyle(lineWidth: 1.5, dash: [4, 3])
    }

    private func weekLegend(_ weekScore: Int) -> some View {
        HStack(spacing: 6) {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 1))
                path.addLine(to: CGPoint(x: legendLineWidth, y: 1))
            }
            .stroke(Color.secondary, style: weekRuleStyle)
            .frame(width: legendLineWidth, height: 2)
            .accessibilityHidden(true)
            Text(.detailChartWeekValue(weekScore))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondary)
        }
    }

    private var selectedBar: ActivityDetailBar? {
        selection.flatMap { id in bars.first { $0.id == id } }
    }

    private var selectedKey: Binding<String?> {
        Binding(
            get: { selection.map(String.init) },
            set: { key in selection = bar(forKey: key)?.id }
        )
    }

    private func key(of bar: ActivityDetailBar) -> String {
        String(bar.id)
    }

    private func bar(forKey key: String?) -> ActivityDetailBar? {
        key.flatMap { key in bars.first { self.key(of: $0) == key } }
    }

    private func isDimmed(_ bar: ActivityDetailBar) -> Bool {
        guard let selectedBar else { return false }
        return selectedBar.id != bar.id
    }
}

#if DEBUG
#Preview("S3.2 Chart selection") {
    @Previewable @State var selection: Int? = 2
    let viewModel = PreviewAppFactory().makeRankingViewModel(for: PreviewCities.lisbon)
    PreparedPreview {
        await viewModel.load()
    } content: {
        List {
            if let detail = viewModel.detail(for: .surfing) {
                DailyScoreChart(bars: detail.bars, weekScore: detail.score, selection: $selection)
                    .padding(.vertical, 8)
            }
        }
    }
}
#endif
