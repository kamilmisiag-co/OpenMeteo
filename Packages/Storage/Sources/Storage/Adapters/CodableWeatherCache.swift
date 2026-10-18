//
//  CodableWeatherCache.swift
//  Storage
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic

public struct CodableWeatherCache: WeatherCaching {
    private let records: any RecordStoring
    private let keys: any WeatherCacheKeying

    public init(records: any RecordStoring, keys: any WeatherCacheKeying) {
        self.records = records
        self.keys = keys
    }

    public func snapshot(for city: City) async -> WeatherSnapshot? {
        records.record(WeatherSnapshot.self, forKey: keys.key(for: city))
    }

    public func store(_ snapshot: WeatherSnapshot) async {
        records.save(snapshot, forKey: keys.key(for: snapshot.city))
    }
}
