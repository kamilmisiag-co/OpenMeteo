//
//  SearchProgressView.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import SwiftUI

struct SearchProgressView: View {
    let isVisible: Bool

    var body: some View {
        ZStack {
            if isVisible {
                ProgressView {
                    Text(.searchSearching)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
