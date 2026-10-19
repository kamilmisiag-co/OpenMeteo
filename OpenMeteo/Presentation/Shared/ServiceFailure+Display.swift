//
//  ServiceFailure+Display.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic

extension ServiceFailure {
    var title: LocalizedStringResource {
        switch self {
        case .offline, .unavailable: .rankingErrorTitle
        case .noUpcomingDays: .rankingErrorNoUpcomingDaysTitle
        }
    }

    var message: LocalizedStringResource {
        switch self {
        case .offline: .rankingErrorOfflineMessage
        case .unavailable: .rankingErrorUnavailableMessage
        case .noUpcomingDays: .rankingErrorNoUpcomingDaysMessage
        }
    }

    var systemImage: String {
        switch self {
        case .offline: "wifi.slash"
        case .unavailable: "exclamationmark.icloud"
        case .noUpcomingDays: "calendar.badge.exclamationmark"
        }
    }
}
