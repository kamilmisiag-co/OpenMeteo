//
//  DailyBars.swift
//  DesignSystem
//
//  Created by Kamil Misiag on 15/10/2026.
//

import SwiftUI
import Utils

public struct DailyBars: View {
    public enum Style: Sendable {
        case card
        case row
    }

    let scores: [Int?]
    var style: Style
    var selectedIndex: Int?
    var initials: [String]

    public init(scores: [Int?], style: Style = .card, selectedIndex: Int? = nil, initials: [String] = []) {
        self.scores = scores
        self.style = style
        self.selectedIndex = selectedIndex
        self.initials = initials
    }

    public var body: some View {
        HStack(alignment: .bottom, spacing: style == .card ? 6 : 3) {
            ForEach(scores.indices, id: \.self) { index in
                switch style {
                case .card: cardBar(index)
                case .row: rowBar(index)
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func isDimmed(_ index: Int) -> Bool {
        selectedIndex != nil && selectedIndex != index
    }

    private func height(for score: Int?, maximum: CGFloat) -> CGFloat {
        guard let score else { return 2 }
        return max(2, maximum * CGFloat(score.clamped(to: 0...100)) / 100)
    }

    private func cardBar(_ index: Int) -> some View {
        let score = scores[index]
        let isSelected = selectedIndex == index
        return VStack(spacing: 4) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: 10, height: 40)
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Rating(score: score).color)
                    .frame(width: 10, height: height(for: score, maximum: 40))
                    .opacity(isDimmed(index) ? 0.3 : 1)
            }
            if initials.indices.contains(index) {
                Text(initials[index])
                    .font(.caption2.weight(isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
        }
        .frame(width: 18)
    }

    private func rowBar(_ index: Int) -> some View {
        let score = scores[index]
        return RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(Rating(score: score).color)
            .frame(width: 4, height: height(for: score, maximum: 16))
            .opacity(isDimmed(index) ? 0.3 : 1)
    }
}

#Preview("Daily bars") {
    let scores: [Int?] = [82, 86, 92, 88, 80, 52, 66]
    VStack(spacing: 24) {
        DailyBars(scores: scores, initials: ["T", "F", "S", "S", "M", "T", "W"])
        DailyBars(scores: scores, selectedIndex: 5, initials: ["T", "F", "S", "S", "M", "T", "W"])
        DailyBars(scores: scores, style: .row)
    }
    .padding()
}
