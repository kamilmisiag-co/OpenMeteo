//
//  ScorePill.swift
//  DesignSystem
//
//  Created by Kamil Misiag on 15/10/2026.
//

import SwiftUI

public struct ScorePill: View {
    public enum Style: Sendable {
        case scoreAndWord
        case scoreOnly
        case wordOnly
    }

    let score: Int?
    var style: Style

    public init(score: Int?, style: Style = .scoreAndWord) {
        self.score = score
        self.style = style
    }

    private var rating: Rating { Rating(score: score) }

    public var body: some View {
        HStack(spacing: 4) {
            if let score {
                if style != .wordOnly {
                    Text(score, format: .number).fontWeight(.bold)
                }
                if style != .scoreOnly {
                    Text(rating.title).fontWeight(.semibold)
                }
            } else if style == .scoreOnly {
                Text(verbatim: "—").fontWeight(.semibold)
            } else {
                Text(rating.title).fontWeight(.semibold)
            }
        }
        .font(style == .wordOnly ? .subheadline : .system(.subheadline, design: .rounded))
        .monospacedDigit()
        .lineLimit(1)
        .fixedSize()
        .padding(.horizontal, style == .wordOnly ? 12 : 10)
        .frame(minWidth: 36, minHeight: style == .wordOnly ? 28 : 26)
        .foregroundStyle(score == nil ? Color.secondary : Color("OnRating", bundle: .module))
        .background(score == nil ? Color(.tertiarySystemFill) : rating.color, in: .capsule)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Score pills") {
    VStack(spacing: 12) {
        HStack {
            ScorePill(score: 92, style: .scoreOnly)
            ScorePill(score: 72)
            ScorePill(score: 48)
            ScorePill(score: 30)
        }
        HStack {
            ScorePill(score: nil)
            ScorePill(score: nil, style: .scoreOnly)
            ScorePill(score: 78, style: .wordOnly)
        }
    }
    .padding()
}
