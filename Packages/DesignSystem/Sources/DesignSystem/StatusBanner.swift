//
//  StatusBanner.swift
//  DesignSystem
//
//  Created by Kamil Misiag on 15/10/2026.
//

import SwiftUI

public struct StatusBanner: View {
    public enum Kind: Hashable, Sendable {
        case stale
        case offline
    }

    let kind: Kind
    let message: String

    public init(kind: Kind, message: String) {
        self.kind = kind
        self.message = message
    }

    public var body: some View {
        Label {
            Text(message)
        } icon: {
            Image(systemName: kind == .stale ? "clock.arrow.circlepath" : "wifi.slash")
        }
        .font(.subheadline)
        .foregroundStyle(.primary)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .background(Color(.tertiarySystemFill), in: .rect(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("status.banner")
    }
}

#Preview("Status banners") {
    VStack(spacing: 12) {
        StatusBanner(kind: .stale, message: "Forecast from 06:10 · Pull to refresh")
        StatusBanner(kind: .offline, message: "Offline · Forecast from Wed 14, 18:20")
    }
    .padding()
}
