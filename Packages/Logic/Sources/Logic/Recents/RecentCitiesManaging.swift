//
//  RecentCitiesManaging.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public protocol RecentCitiesManaging: Sendable {
    func recentCities() -> [City]
    func recordVisit(to city: City) -> [City]
    func remove(_ cityIDs: Set<City.ID>) -> [City]
    func removeAll()
}
