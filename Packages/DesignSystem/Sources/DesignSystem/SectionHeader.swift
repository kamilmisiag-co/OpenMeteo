//
//  SectionHeader.swift
//  DesignSystem
//
//  Created by Kamil Misiag on 15/10/2026.
//

import SwiftUI

public struct SectionHeader<Title: View, Trailing: View>: View {
    let title: Title
    let trailing: Trailing

    public init(@ViewBuilder title: () -> Title, @ViewBuilder trailing: () -> Trailing) {
        self.title = title()
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            title
            Spacer()
            trailing
                .font(.body)
        }
        .textCase(nil)
    }
}

extension SectionHeader where Trailing == EmptyView {
    public init(@ViewBuilder title: () -> Title) {
        self.init(title: title, trailing: { EmptyView() })
    }
}

#Preview("Section headers") {
    List {
        Section {
            Text(verbatim: "Lisbon")
        } header: {
            SectionHeader {
                Text(verbatim: "Recent")
            } trailing: {
                Button(action: {}) { Text(verbatim: "Clear") }
            }
        }
        .headerProminence(.increased)
        Section {
            Text(verbatim: "Lisbon")
        } header: {
            SectionHeader { Text(verbatim: "Results") }
        }
        .headerProminence(.increased)
    }
}
