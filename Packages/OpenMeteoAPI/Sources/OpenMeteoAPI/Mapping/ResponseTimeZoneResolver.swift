//
//  ResponseTimeZoneResolver.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation

public struct ResponseTimeZoneResolver: ForecastTimeZoneResolving {
    private let fallbackTimeZone: TimeZone

    public init(fallbackTimeZone: TimeZone) {
        self.fallbackTimeZone = fallbackTimeZone
    }

    public func timeZone(of response: ForecastResponseDTO) -> TimeZone {
        TimeZone(identifier: response.timezone) ?? fallbackTimeZone
    }
}
