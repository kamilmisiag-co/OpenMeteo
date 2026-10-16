//
//  RankingRow.swift
//  DesignSystem
//
//  Created by Kamil Misiag on 15/10/2026.
//

import SwiftUI

public struct RankingRow: View {
    let rank: Int
    let title: String
    let systemImage: String
    let reason: String
    let score: Int?
    let dailyScores: [Int?]
    let selectedDay: Int?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        rank: Int,
        title: String,
        systemImage: String,
        reason: String,
        score: Int?,
        dailyScores: [Int?],
        selectedDay: Int?
    ) {
        self.rank = rank
        self.title = title
        self.systemImage = systemImage
        self.reason = reason
        self.score = score
        self.dailyScores = dailyScores
        self.selectedDay = selectedDay
    }

    public var body: some View {
        let isLarge = dynamicTypeSize.isAccessibilitySize
        let isSuitable = score != nil
        HStack(alignment: isLarge ? .top : .center, spacing: 12) {
            Text(rank, format: .number)
                .font(.system(.subheadline, design: .rounded).bold())
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(minWidth: 12)
            ActivityIcon(systemImage: systemImage, isEnabled: isSuitable)
            VStack(alignment: .leading, spacing: isLarge ? 8 : 1) {
                Text(title)
                    .foregroundStyle(isSuitable ? .primary : .secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(reason)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if isLarge {
                    ScorePill(score: score)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if !isLarge {
                VStack(alignment: .trailing, spacing: 8) {
                    ScorePill(score: score)
                    if isSuitable {
                        DailyBars(scores: dailyScores, style: .row, selectedIndex: selectedDay)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Ranking rows") {
    List {
        RankingRow(
            rank: 2,
            title: "Outdoor sightseeing",
            systemImage: "binoculars.fill",
            reason: "Sunny and 22–24° until Mon; rain Tue",
            score: 72,
            dailyScores: [84, 90, 88, 82, 70, 30, 60],
            selectedDay: nil
        )
        RankingRow(
            rank: 4,
            title: "Skiing",
            systemImage: "figure.skiing.downhill",
            reason: "No snow forecast; highs 19–24°",
            score: nil,
            dailyScores: Array(repeating: nil, count: 7),
            selectedDay: nil
        )
    }
}
