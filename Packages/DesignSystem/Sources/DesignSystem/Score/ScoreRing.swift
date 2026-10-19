//
//  ScoreRing.swift
//  DesignSystem
//
//  Created by Kamil Misiag on 15/10/2026.
//

import SwiftUI
import Utils

public struct ScoreRing: View {
    public enum Size: Sendable {
        case regular
        case large
    }

    let score: Int?
    var size: Size

    @ScaledMetric(relativeTo: .title2) private var regularDiameter: CGFloat = 64
    @ScaledMetric(relativeTo: .largeTitle) private var largeDiameter: CGFloat = 120

    public init(score: Int?, size: Size = .regular) {
        self.score = score
        self.size = size
    }

    private var diameter: CGFloat { size == .regular ? regularDiameter : largeDiameter }
    private var rating: Rating { Rating(score: score) }

    public var body: some View {
        let lineWidth = (diameter * 0.11).rounded()
        ZStack {
            Circle()
                .inset(by: lineWidth / 2)
                .stroke(Color(.systemGray5), lineWidth: lineWidth)

            if let score {
                Circle()
                    .inset(by: lineWidth / 2)
                    .trim(from: 0, to: CGFloat(score).fraction(of: 0...100))
                    .stroke(rating.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }

            VStack(spacing: 2) {
                Group {
                    if let score {
                        Text(score, format: .number)
                    } else {
                        Text(verbatim: "—")
                    }
                }
                .font(.system(size: diameter * 0.36, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(score == nil ? Color.secondary : Color.primary)
                .contentTransition(.numericText())

                if size == .large, score != nil {
                    Text(.scoreRingOutOf100)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            .minimumScaleFactor(0.6)
        }
        .frame(width: diameter, height: diameter)
        .animation(.default, value: score)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        guard let score else { return String(localized: rating.title) }
        return String(localized: .scoreRingAccessibility(score, String(localized: rating.title)))
    }
}

#Preview("Score rings") {
    HStack(spacing: 24) {
        ScoreRing(score: 78)
        ScoreRing(score: 48)
        ScoreRing(score: 78, size: .large)
        ScoreRing(score: nil, size: .large)
    }
    .padding()
}
