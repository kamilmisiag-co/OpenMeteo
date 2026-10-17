//
//  WeatherCaching.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public protocol WeatherCaching: Sendable {
    func snapshot(for city: City) async -> WeatherSnapshot?
    func store(_ snapshot: WeatherSnapshot) async
}
