//
//  AttributionFooter.swift
//  DesignSystem
//
//  Created by Kamil Misiag on 15/10/2026.
//

import SwiftUI

public struct AttributionFooter: View {
    var updated: String?

    private static let openMeteo = URL(string: "https://open-meteo.com/")!

    public init(updated: String? = nil) {
        self.updated = updated
    }

    public var body: some View {
        VStack(spacing: 2) {
            if let updated {
                Text(.attributionUpdated(updated))
                    .foregroundStyle(.secondary)
            }
            Link(destination: Self.openMeteo) {
                Text(.attributionOpenMeteo)
            }
        }
        .font(.footnote)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}

#Preview("Attribution") {
    AttributionFooter(updated: "09:42")
        .padding()
}
