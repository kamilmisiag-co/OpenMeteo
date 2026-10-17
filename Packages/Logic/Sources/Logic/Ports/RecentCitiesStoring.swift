//
//  RecentCitiesStoring.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public protocol RecentCitiesStoring: Sendable {
    func load() -> [City]
    func save(_ cities: [City])
}
