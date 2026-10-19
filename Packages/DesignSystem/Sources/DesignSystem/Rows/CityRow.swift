//
//  CityRow.swift
//  DesignSystem
//
//  Created by Kamil Misiag on 15/10/2026.
//

import SwiftUI
import Utils

public struct CityRow: View {
    let name: String
    let subtitle: String
    let flag: String?
    var highlight: String?

    @ScaledMetric(relativeTo: .body) private var flagDiameter: CGFloat = 40

    public init(name: String, subtitle: String, flag: String?, highlight: String? = nil) {
        self.name = name
        self.subtitle = subtitle
        self.flag = flag
        self.highlight = highlight
    }

    public var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color(.tertiarySystemFill))
                if let flag {
                    Text(verbatim: flag).font(.title2)
                } else {
                    Image(systemName: "globe").foregroundStyle(.secondary)
                }
            }
            .frame(width: flagDiameter, height: flagDiameter)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.body)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    private var title: AttributedString {
        AttributedString(name).applying(AttributeContainer().font(.body.weight(.semibold)), toPrefixMatching: highlight ?? "")
    }
}

#Preview("City rows") {
    List {
        CityRow(name: "Lisbon", subtitle: "Lisbon, Portugal", flag: "🇵🇹", highlight: "Lis")
        CityRow(name: "Zakopane", subtitle: "Lesser Poland, Poland", flag: "🇵🇱")
        CityRow(name: "Atlantis", subtitle: "Ocean", flag: nil)
        CityRow(name: "Lisbon", subtitle: "Lisbon, Portugal", flag: "🇵🇹").redacted(reason: .placeholder)
    }
}
