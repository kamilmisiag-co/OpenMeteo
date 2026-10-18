//
//  ForecastFailureView.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic
import SwiftUI

struct ForecastFailureView: View {
    let failure: ServiceFailure
    let onRetry: () async -> Void

    var body: some View {
        ContentUnavailableView {
            Label {
                Text(failure.title)
            } icon: {
                Image(systemName: failure.systemImage)
            }
        } description: {
            Text(failure.message)
        } actions: {
            Button(.rankingErrorRetry) {
                Task { await onRetry() }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
