//
//  LocaleForecastFormatFactory.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation

struct LocaleForecastFormatFactory: ForecastFormatMaking {
    private let locale: Locale
    private let deviceTimeZone: TimeZone

    init(locale: Locale, deviceTimeZone: TimeZone) {
        self.locale = locale
        self.deviceTimeZone = deviceTimeZone
    }

    func format(forCityIn timeZone: TimeZone) -> any ForecastFormatting {
        ForecastFormat(locale: locale, cityTimeZone: timeZone, deviceTimeZone: deviceTimeZone)
    }
}
