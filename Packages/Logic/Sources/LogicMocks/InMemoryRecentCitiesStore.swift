//
//  InMemoryRecentCitiesStore.swift
//  LogicMocks
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic
import Synchronization

public final class InMemoryRecentCitiesStore: RecentCitiesStoring {
    private struct State {
        var cities: [City]
        var saveCount = 0
    }

    private let state: Mutex<State>

    public init(cities: [City]) {
        state = Mutex(State(cities: cities))
    }

    public var cities: [City] {
        state.withLock { $0.cities }
    }

    public var saveCount: Int {
        state.withLock { $0.saveCount }
    }

    public func load() -> [City] {
        cities
    }

    public func save(_ cities: [City]) {
        state.withLock { state in
            state.cities = cities
            state.saveCount += 1
        }
    }
}
