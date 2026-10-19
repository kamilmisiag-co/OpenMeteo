//
//  FactorKind+Display.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic

extension Factor.Kind {
    var cause: LocalizedStringResource {
        switch self {
        case .wind: .factorWindCause
        case .rain: .factorRainCause
        case .temperature: .factorTemperatureCause
        case .thunderstorm: .factorThunderstormCause
        case .snowfall: .factorSnowfallCause
        }
    }
}
