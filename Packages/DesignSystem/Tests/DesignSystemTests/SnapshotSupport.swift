//
//  SnapshotSupport.swift
//  DesignSystemTests
//
//  Created by Kamil Misiag on 15/10/2026.
//

import SnapshotTesting
import SwiftUI
import UIKit

enum Variant: String, CaseIterable {
    case light
    case dark
    case ax1

    var traits: UITraitCollection {
        UITraitCollection { traits in
            traits.displayScale = 2
            traits.userInterfaceStyle = self == .dark ? .dark : .light
            traits.preferredContentSizeCategory = self == .ax1 ? .accessibilityMedium : .large
        }
    }

    var dynamicTypeSize: DynamicTypeSize {
        self == .ax1 ? .accessibility1 : .large
    }
}

@MainActor
func assertComponent(
    _ view: some View,
    width: CGFloat = 370,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    testName: String = #function,
    line: UInt = #line,
    column: UInt = #column
) {
    for variant in Variant.allCases {
        assertSnapshot(
            of: view
                .frame(width: width)
                .padding(16)
                .background(Color(.systemGroupedBackground))
                .environment(\.locale, Locale(identifier: "en_GB"))
                .dynamicTypeSize(variant.dynamicTypeSize),
            as: .image(perceptualPrecision: 0.98, layout: .sizeThatFits, traits: variant.traits),
            named: variant.rawValue,
            fileID: fileID,
            file: filePath,
            testName: testName,
            line: line,
            column: column
        )
    }
}

extension View {
    func listCell() -> some View {
        padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 24, style: .continuous))
    }
}
