//
//  ForecastTimeZoneResolving.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation

public protocol ForecastTimeZoneResolving: Sendable {
    func timeZone(of response: ForecastResponseDTO) -> TimeZone
}
