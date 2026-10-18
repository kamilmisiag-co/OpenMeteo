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

    var helps: LocalizedStringResource {
        switch self {
        case .skiing: .activitySkiingHelps
        case .surfing: .activitySurfingHelps
        case .outdoorSightseeing: .activityOutdoorSightseeingHelps
        case .indoorSightseeing: .activityIndoorSightseeingHelps
        }
    }

    var hurts: LocalizedStringResource {
        switch self {
        case .skiing: .activitySkiingHurts
        case .surfing: .activitySurfingHurts
        case .outdoorSightseeing: .activityOutdoorSightseeingHurts
        case .indoorSightseeing: .activityIndoorSightseeingHurts
        }
    }

    var scoringNote: LocalizedStringResource {
        switch self {
        case .skiing: .activitySkiingScoringNote
        case .surfing: .activitySurfingScoringNote
        case .outdoorSightseeing: .activityOutdoorSightseeingScoringNote
        case .indoorSightseeing: .activityIndoorSightseeingScoringNote
        }
    }
}
