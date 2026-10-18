//
//  LabelledFormatFactory.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
@testable import OpenMeteo

@MainActor
final class LabelledFormatFactory: ForecastFormatMaking {
    private(set) var madeFormats: [LabelledForecastFormat] = []

    var requestedTimeZones: [TimeZone] {
        madeFormats.map(\.timeZone)
    }

    func format(forCityIn timeZone: TimeZone) -> any ForecastFormatting {
        let format = LabelledForecastFormat(timeZone: timeZone)
        madeFormats.append(format)
        return format
    }

    func handedOut(_ format: any ForecastFormatting) -> Bool {
        madeFormats.contains { $0 === (format as? LabelledForecastFormat) }
    }
}
