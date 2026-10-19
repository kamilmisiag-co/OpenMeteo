//
//  DayScoreRow.swift
//  DesignSystem
//
//  Created by Kamil Misiag on 15/10/2026.
//

import SwiftUI

public struct DayScoreRow: View {
    let label: String
    let isBest: Bool
    let symbolName: String
    let conditionTitle: String
    let high: String
    let low: String
    let score: Int?
    let caption: String

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        label: String,
        isBest: Bool,
        symbolName: String,
        conditionTitle: String,
        high: String,
        low: String,
        score: Int?,
        caption: String
    ) {
        self.label = label
        self.isBest = isBest
        self.symbolName = symbolName
        self.conditionTitle = conditionTitle
        self.high = high
        self.low = low
        self.score = score
        self.caption = caption
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6))
                : AnyLayout(HStackLayout(spacing: 10))
            layout {
                HStack(spacing: 6) {
                    Text(label)
                    if isBest {
                        Text(.dayScoreRowBest)
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .foregroundStyle(.tint)
                            .background(Color.accentColor.opacity(0.12), in: .capsule)
                    }
                }
                .frame(minWidth: 96, alignment: .leading)

                HStack(spacing: 8) {
                    Image(systemName: symbolName)
                        .symbolRenderingMode(.multicolor)
                        .accessibilityLabel(conditionTitle)
                    Text(high).fontWeight(.semibold)
                    Text(verbatim: "/ \(low)").foregroundStyle(.secondary)
                }
                .font(.subheadline)
                .monospacedDigit()

                if !dynamicTypeSize.isAccessibilitySize {
                    Spacer(minLength: 0)
                }
                ScorePill(score: score, style: .scoreOnly)
            }
            Text(caption)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Day score rows") {
    List {
        DayScoreRow(
            label: "Sat 17", isBest: true, symbolName: "cloud.sun.fill", conditionTitle: "Partly cloudy",
            high: "24°", low: "17°", score: 92, caption: "Wind 12 km/h · Gusts 20 km/h · Rain 5%"
        )
        DayScoreRow(
            label: "Tue 20", isBest: false, symbolName: "cloud.rain.fill", conditionTitle: "Rain",
            high: "19°", low: "15°", score: nil, caption: "Snow 0 cm · High 19°"
        )
    }
}
