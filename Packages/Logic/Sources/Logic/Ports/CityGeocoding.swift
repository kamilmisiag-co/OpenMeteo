//
//  CityGeocoding.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public protocol CityGeocoding: Sendable {
    func cities(named name: String) async throws -> [City]
}
