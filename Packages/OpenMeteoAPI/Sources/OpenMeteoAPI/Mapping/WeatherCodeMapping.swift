//
//  WeatherCodeMapping.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic

public protocol WeatherCodeMapping: Sendable {
    func condition(forCode code: Int) -> WeatherCondition?
}
