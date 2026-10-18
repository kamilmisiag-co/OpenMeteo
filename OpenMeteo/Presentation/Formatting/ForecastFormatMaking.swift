//
//  ForecastFormatMaking.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation

protocol ForecastFormatMaking {
    func format(forCityIn timeZone: TimeZone) -> any ForecastFormatting
}
