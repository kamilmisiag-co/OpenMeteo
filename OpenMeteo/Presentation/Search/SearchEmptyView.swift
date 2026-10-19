//
//  SearchEmptyView.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import SwiftUI

struct SearchEmptyView: View {
    let dayCount: Int

    var body: some View {
        ContentUnavailableView {
            Label {
                Text(.searchEmptyTitle)
            } icon: {
                Image(systemName: "map")
            }
        } description: {
            VStack(spacing: 12) {
                Text(.searchEmptyMessage(dayCount))
                Text(.searchEmptyTip)
                    .font(.footnote)
            }
        }
    }
}
