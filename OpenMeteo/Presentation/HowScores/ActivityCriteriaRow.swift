//
//  ActivityCriteriaRow.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import DesignSystem
import Foundation
import Logic
import SwiftUI

struct ActivityCriteriaRow: View {
    let activity: Activity

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ActivityIcon(systemImage: activity.systemImage)
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.headline)
                criterion(.howScoresActivitiesHelps, activity.helps)
                criterion(.howScoresActivitiesHurts, activity.hurts)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    private func criterion(_ label: LocalizedStringResource, _ value: LocalizedStringResource) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 4))
        return layout {
            Text(label)
                .fontWeight(.semibold)
            Text(value)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.footnote)
    }
}
