//
//  Activity+Display.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic

extension Activity {
    var title: LocalizedStringResource {
        switch self {
        case .skiing: .activitySkiingTitle
        case .surfing: .activitySurfingTitle
        case .outdoorSightseeing: .activityOutdoorSightseeingTitle
        case .indoorSightseeing: .activityIndoorSightseeingTitle
        }
    }

    var systemImage: String {
        switch self {
        case .skiing: "figure.skiing.downhill"
        case .surfing: "figure.surfing"
        case .outdoorSightseeing: "binoculars.fill"
        case .indoorSightseeing: "building.columns.fill"
        }
    }
}
