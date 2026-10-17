//
//  InMemoryWeatherCache.swift
//  LogicMocks
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic

public actor InMemoryWeatherCache: WeatherCaching {
    private var snapshots: [City.ID: WeatherSnapshot]
    public private(set) var storedSnapshots: [WeatherSnapshot] = []

    public init(snapshots: [WeatherSnapshot]) {
        self.snapshots = Dictionary(snapshots.map { ($0.city.id, $0) }, uniquingKeysWith: { _, latest in latest })
    }

    public func snapshot(for city: City) -> WeatherSnapshot? {
        snapshots[city.id]
    }

    public func store(_ snapshot: WeatherSnapshot) {
        snapshots[snapshot.city.id] = snapshot
        storedSnapshots.append(snapshot)
    }
}
