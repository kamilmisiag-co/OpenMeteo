//
//  ScriptedRecentCitiesManager.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic
import Synchronization

final class ScriptedRecentCitiesManager: RecentCitiesManaging {
    enum Call: Hashable, Sendable {
        case recentCities
        case recordVisit(City)
        case remove(Set<City.ID>)
        case removeAll
    }

    private let cities: [City]
    private let afterVisit: [City]
    private let afterRemoval: [City]
    private let recorded = Mutex<[Call]>([])

    init(cities: [City] = [], afterVisit: [City] = [], afterRemoval: [City] = []) {
        self.cities = cities
        self.afterVisit = afterVisit
        self.afterRemoval = afterRemoval
    }

    var calls: [Call] {
        recorded.withLock { $0 }
    }

    func recentCities() -> [City] {
        record(.recentCities)
        return cities
    }

    func recordVisit(to city: City) -> [City] {
        record(.recordVisit(city))
        return afterVisit
    }

    func remove(_ cityIDs: Set<City.ID>) -> [City] {
        record(.remove(cityIDs))
        return afterRemoval
    }

    func removeAll() {
        record(.removeAll)
    }

    private func record(_ call: Call) {
        recorded.withLock { $0.append(call) }
    }
}
