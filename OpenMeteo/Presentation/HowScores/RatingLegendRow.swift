//
//  RatingLegendRow.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import DesignSystem
import SwiftUI

struct RatingLegendRow: View {
    let rating: Rating

    @ScaledMetric(relativeTo: .body) private var dotDiameter: CGFloat = 12

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(rating.color)
                .frame(width: dotDiameter, height: dotDiameter)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(rating.title)
                if rating == .notSuitable {
                    Text(.howScoresRatingsNotSuitable)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            if let range = rating.rangeText {
                Text(range)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
