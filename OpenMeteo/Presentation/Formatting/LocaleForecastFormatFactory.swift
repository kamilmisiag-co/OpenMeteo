//
//  LocaleForecastFormatFactory.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic

protocol ForecastFormatMaking {
    func format(for city: City) -> any ForecastFormatting
}

struct LocaleForecastFormatFactory: ForecastFormatMaking {
    private let locale: Locale
    private let deviceTimeZone: TimeZone
    private let fallbackTimeZone: TimeZone

    init(locale: Locale, deviceTimeZone: TimeZone, fallbackTimeZone: TimeZone) {
        self.locale = locale
        self.deviceTimeZone = deviceTimeZone
        self.fallbackTimeZone = fallbackTimeZone
    }

    func format(for city: City) -> any ForecastFormatting {
        ForecastFormat(locale: locale, cityTimeZone: city.timeZone ?? fallbackTimeZone, deviceTimeZone: deviceTimeZone)
    }
}
