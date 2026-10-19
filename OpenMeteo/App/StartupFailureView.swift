//
//  StartupFailureView.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import SwiftUI

struct StartupFailureView: View {
    var body: some View {
        ContentUnavailableView {
            Label {
                Text(.startupFailureTitle)
            } icon: {
                Image(systemName: "exclamationmark.triangle")
            }
        } description: {
            Text(.startupFailureMessage)
        }
    }
}

#if DEBUG
#Preview("Startup failure") {
    StartupFailureView()
}
#endif
