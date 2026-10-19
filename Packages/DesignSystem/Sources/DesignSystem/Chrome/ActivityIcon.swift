//
//  ActivityIcon.swift
//  DesignSystem
//
//  Created by Kamil Misiag on 15/10/2026.
//

import SwiftUI

public struct ActivityIcon: View {
    public enum Size: Sendable {
        case small
        case large
    }

    let systemImage: String
    var size: Size
    var isEnabled: Bool

    @ScaledMetric(relativeTo: .body) private var smallDiameter: CGFloat = 40
    @ScaledMetric(relativeTo: .title2) private var largeDiameter: CGFloat = 56

    public init(systemImage: String, size: Size = .small, isEnabled: Bool = true) {
        self.systemImage = systemImage
        self.size = size
        self.isEnabled = isEnabled
    }

    public var body: some View {
        let diameter = size == .small ? smallDiameter : largeDiameter
        let tint = isEnabled ? Color.accentColor : Color.gray
        Image(systemName: systemImage)
            .font(.system(size: diameter * 0.5, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: diameter, height: diameter)
            .background(tint.opacity(0.12), in: .circle)
            .accessibilityHidden(true)
    }
}

#Preview("Activity icons") {
    HStack(spacing: 16) {
        ForEach(["figure.skiing.downhill", "figure.surfing", "binoculars.fill", "building.columns.fill"], id: \.self) { symbol in
            ActivityIcon(systemImage: symbol, size: .large)
        }
        ActivityIcon(systemImage: "figure.skiing.downhill", isEnabled: false)
    }
    .padding()
}
