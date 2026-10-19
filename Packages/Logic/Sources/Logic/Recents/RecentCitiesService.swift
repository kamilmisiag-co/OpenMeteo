//
//  RecentCitiesService.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Utils

public protocol RecentCitiesManaging: Sendable {
    func recentCities() -> [City]
    func recordVisit(to city: City) -> [City]
    func remove(_ cityIDs: Set<City.ID>) -> [City]
    func removeAll()
}

public struct RecentCitiesService: RecentCitiesManaging {
    private let store: any RecentCitiesStoring
    private let maximumCount: Int

    public init(store: any RecentCitiesStoring, maximumCount: Int) {
        self.store = store
        self.maximumCount = maximumCount
    }

    public func recentCities() -> [City] {
        normalized(store.load())
    }

    public func recordVisit(to city: City) -> [City] {
        let stored = store.load()
        return savingIfChanged(normalized([city] + stored), from: stored)
    }

    public func remove(_ cityIDs: Set<City.ID>) -> [City] {
        let stored = store.load()
        return savingIfChanged(normalized(stored).filter { !cityIDs.contains($0.id) }, from: stored)
    }

    public func removeAll() {
        guard !store.load().isEmpty else { return }
        store.save([])
    }

    private func normalized(_ cities: [City]) -> [City] {
        Array(cities.uniqued(by: \.id).prefix(maximumCount))
    }

    private func savingIfChanged(_ cities: [City], from stored: [City]) -> [City] {
        if cities != stored {
            store.save(cities)
        }
        return cities
    }
}
