//
//  AttributionFooter.swift
//  DesignSystem
//
//  Created by Kamil Misiag on 15/10/2026.
//

import SwiftUI

public struct AttributionFooter: View {
    var updated: String?
    var link: URL?

    public init(updated: String? = nil, link: URL?) {
        self.updated = updated
        self.link = link
    }

    public var body: some View {
        VStack(spacing: 2) {
            if let updated {
                Text(.attributionUpdated(updated))
                    .foregroundStyle(.secondary)
            }
            if let link {
                Link(destination: link) {
                    Text(.attributionOpenMeteo)
                }
            } else {
                Text(.attributionOpenMeteo)
                    .foregroundStyle(.secondary)
            }
        }
        .font(.footnote)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}

#Preview("Attribution") {
    AttributionFooter(updated: "09:42", link: URL(string: "https://open-meteo.com/"))
        .padding()
}
