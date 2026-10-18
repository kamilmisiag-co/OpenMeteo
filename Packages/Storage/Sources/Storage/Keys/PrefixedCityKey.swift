//
//  PrefixedCityKey.swift
//  Storage
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic

public struct PrefixedCityKey: WeatherCacheKeying {
    private let prefix: String

    public init(prefix: String) {
        self.prefix = prefix
    }

    public func key(for city: City) -> String {
        prefix + String(city.id)
    }
}
