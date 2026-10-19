//
//  WeatherCondition+Display.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic

extension WeatherCondition {
    var title: LocalizedStringResource {
        switch self {
        case .clear: .conditionClear
        case .partlyCloudy: .conditionPartlyCloudy
        case .cloudy: .conditionCloudy
        case .fog: .conditionFog
        case .drizzle: .conditionDrizzle
        case .rain: .conditionRain
        case .snow: .conditionSnow
        case .thunderstorm: .conditionThunderstorm
        }
    }

    var systemImage: String {
        switch self {
        case .clear: "sun.max.fill"
        case .partlyCloudy: "cloud.sun.fill"
        case .cloudy: "cloud.fill"
        case .fog: "cloud.fog.fill"
        case .drizzle: "cloud.drizzle.fill"
        case .rain: "cloud.rain.fill"
        case .snow: "cloud.snow.fill"
        case .thunderstorm: "cloud.bolt.rain.fill"
        }
    }
}
