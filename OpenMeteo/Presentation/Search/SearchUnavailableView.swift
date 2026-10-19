//
//  SearchUnavailableView.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic
import SwiftUI

struct SearchUnavailableView: View {
    let failure: SearchFailure
    let onRetry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label {
                Text(.searchUnavailableTitle)
            } icon: {
                Image(systemName: "wifi.exclamationmark")
            }
        } description: {
            Text(failure.message)
        } actions: {
            Button(.searchUnavailableRetry, action: onRetry)
            .buttonStyle(.borderedProminent)
        }
    }
}
