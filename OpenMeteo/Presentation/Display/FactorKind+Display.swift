//
//  FactorKind+Display.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic

extension Factor.Kind {
    var title: LocalizedStringResource {
        switch self {
        case .wind: .factorWindTitle
        case .rain: .factorRainTitle
        case .temperature: .factorTemperatureTitle
        case .thunderstorm: .factorThunderstormTitle
        case .snowfall: .factorSnowfallTitle
        }
    }

    var cause: LocalizedStringResource {
        switch self {
        case .wind: .factorWindCause
        case .rain: .factorRainCause
        case .temperature: .factorTemperatureCause
        case .thunderstorm: .factorThunderstormCause
        case .snowfall: .factorSnowfallCause
        }
    }

    var emptyChartTitle: LocalizedStringResource {
        switch self {
        case .snowfall: .detailChartEmptySnowfall
        case .thunderstorm: .detailChartEmptyThunderstorm
        case .wind, .rain, .temperature: .detailChartEmptyOther
        }
    }

    var emptyChartSymbol: String {
        switch self {
        case .snowfall: "snowflake"
        case .thunderstorm: "cloud.bolt.rain"
        case .wind: "wind"
        case .rain: "cloud.rain"
        case .temperature: "thermometer.medium"
        }
    }
}
