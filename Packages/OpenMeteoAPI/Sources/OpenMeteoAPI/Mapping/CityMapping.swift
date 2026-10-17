//
//  CityMapping.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic

public protocol CityMapping: Sendable {
    func city(from result: GeocodingResultDTO) -> City?
}
