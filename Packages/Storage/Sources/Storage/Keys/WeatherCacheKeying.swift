//
//  WeatherCacheKeying.swift
//  Storage
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic

public protocol WeatherCacheKeying: Sendable {
    func key(for city: City) -> String
}
