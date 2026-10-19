//
//  DailyScoreCallout.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import DesignSystem
import SwiftUI

struct DailyScoreCallout: View {
    let bar: ActivityDetailBar

    @ScaledMetric(relativeTo: .subheadline) private var dotDiameter: CGFloat = 8

    var body: some View {
        let rating = Rating(score: bar.score)
        VStack(alignment: .leading, spacing: 1) {
            Text(bar.calloutTitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                Circle()
                    .fill(rating.color)
                    .frame(width: dotDiameter, height: dotDiameter)
                if let score = bar.score {
                    Text(score, format: .number)
                        .font(.system(.headline, design: .rounded))
                        .monospacedDigit()
                }
                Text(rating.title)
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.background.secondary, in: .rect(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.separator)
        }
        .accessibilityElement(children: .combine)
    }
}
