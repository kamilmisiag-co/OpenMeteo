//
//  FactorRow.swift
//  DesignSystem
//
//  Created by Kamil Misiag on 15/10/2026.
//

import SwiftUI

public struct FactorRow: View {
    let title: String
    let summary: String
    let value: String?
    let helps: Bool

    public init(title: String, summary: String, value: String?, helps: Bool) {
        self.title = title
        self.summary = summary
        self.value = value
        self.helps = helps
    }

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: helps ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.title3)
                .foregroundStyle(helps ? Color.green : Color.orange)
                .accessibilityLabel(helps ? Text(.factorRowHelps) : Text(.factorRowHurts))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                Text(summary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            if let value {
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Factor rows") {
    List {
        FactorRow(title: "Wind", summary: "Light Thu–Mon, strong Tue", value: "10–32 km/h", helps: false)
        FactorRow(title: "Air temperature", summary: "Mild all week", value: "15–24°", helps: true)
        FactorRow(title: "Thunderstorms", summary: "None forecast", value: nil, helps: true)
    }
}
