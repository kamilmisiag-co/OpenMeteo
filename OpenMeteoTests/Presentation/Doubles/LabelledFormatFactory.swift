//
//  LabelledFormatFactory.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic
@testable import OpenMeteo

@MainActor
final class LabelledFormatFactory: ForecastFormatMaking {
    private(set) var requestedCities: [City] = []
    private var madeFormats: [LabelledForecastFormat] = []

    func format(for city: City) -> any ForecastFormatting {
        let format = LabelledForecastFormat(timeZone: city.timeZone ?? .gmt)
        requestedCities.append(city)
        madeFormats.append(format)
        return format
    }

    func handedOut(_ format: any ForecastFormatting) -> Bool {
        madeFormats.contains { $0 === (format as? LabelledForecastFormat) }
    }
}
