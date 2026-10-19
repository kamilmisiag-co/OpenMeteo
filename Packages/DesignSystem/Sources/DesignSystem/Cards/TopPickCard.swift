//
//  TopPickCard.swift
//  DesignSystem
//
//  Created by Kamil Misiag on 15/10/2026.
//

import SwiftUI

public struct TopPickCard: View {
    let title: String
    let systemImage: String
    let reason: String
    let score: Int?
    let dailyScores: [Int?]
    let eyebrow: String
    let dayInitials: [String]
    let selectedDay: Int?
    let bestDay: String?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        title: String,
        systemImage: String,
        reason: String,
        score: Int?,
        dailyScores: [Int?],
        eyebrow: String,
        dayInitials: [String],
        selectedDay: Int?,
        bestDay: String?
    ) {
        self.title = title
        self.systemImage = systemImage
        self.reason = reason
        self.score = score
        self.dailyScores = dailyScores
        self.eyebrow = eyebrow
        self.dayInitials = dayInitials
        self.selectedDay = selectedDay
        self.bestDay = bestDay
    }

    public var body: some View {
        let isLarge = dynamicTypeSize.isAccessibilitySize
        let layout = isLarge
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 12))

        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            layout {
                ActivityIcon(systemImage: systemImage, size: .large, isEnabled: score != nil)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.title2.bold())
                        .fixedSize(horizontal: false, vertical: true)
                    Text(reason)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(spacing: 3) {
                    ScoreRing(score: score)
                    Text(Rating(score: score).title)
                        .font(.footnote.weight(.semibold))
                }
            }

            if !isLarge {
                HStack(alignment: .bottom, spacing: 12) {
                    DailyBars(scores: dailyScores, selectedIndex: selectedDay, initials: dayInitials)
                    Spacer(minLength: 0)
                    if let bestDay {
                        Text(bestDay)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                            .padding(.bottom, 18)
                    }
                }
            } else if let bestDay {
                Text(bestDay)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Top pick card") {
    List {
        TopPickCard(
            title: "Surfing",
            systemImage: "figure.surfing",
            reason: "Light winds Thu–Mon; windy and wet Tue",
            score: 78,
            dailyScores: [82, 86, 92, 88, 80, 52, 66],
            eyebrow: "Top pick",
            dayInitials: ["T", "F", "S", "S", "M", "T", "W"],
            selectedDay: nil,
            bestDay: "Best day: Sat 17 · 92"
        )
    }
}
