//
//  PreviewRecentCitiesStore.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

#if DEBUG
import Logic
import Synchronization

nonisolated final class PreviewRecentCitiesStore: RecentCitiesStoring {
    private let cities: Mutex<[City]>

    init(cities: [City] = []) {
        self.cities = Mutex(cities)
    }

    func load() -> [City] {
        cities.withLock { $0 }
    }

    func save(_ cities: [City]) {
        self.cities.withLock { $0 = cities }
    }
}
#endif
