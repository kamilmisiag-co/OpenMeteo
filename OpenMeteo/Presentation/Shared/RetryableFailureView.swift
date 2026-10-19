//
//  RetryableFailureView.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 19/10/2026.
//

import Logic
import SwiftUI

struct RetryableFailureView: View {
    let title: LocalizedStringResource
    let systemImage: String
    let message: LocalizedStringResource
    let onRetry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label {
                Text(title)
            } icon: {
                Image(systemName: systemImage)
            }
        } description: {
            Text(message)
        } actions: {
            Button(.failureRetry, action: onRetry)
                .buttonStyle(.borderedProminent)
        }
    }
}

extension RetryableFailureView {
    init(failure: ServiceFailure, onRetry: @escaping () async -> Void) {
        self.init(title: failure.title, systemImage: failure.systemImage, message: failure.message) {
            Task { await onRetry() }
        }
    }
}
