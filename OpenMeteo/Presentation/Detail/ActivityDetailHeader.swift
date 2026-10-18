//
//  ActivityDetailHeader.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import DesignSystem
import SwiftUI

struct ActivityDetailHeader: View {
    let detail: ActivityDetail

    var body: some View {
        VStack(spacing: 8) {
            ScoreRing(score: detail.score, size: .large)
            ScorePill(score: detail.score, style: .wordOnly)
                .padding(.top, 4)
            Text(detail.rank)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(detail.reason)
                .font(.body)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let bestDay = detail.bestDay {
                Text(bestDay)
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
