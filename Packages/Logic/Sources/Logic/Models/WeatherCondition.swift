//
//  WeatherCondition.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public enum WeatherCondition: String, CaseIterable, Codable, Hashable, Sendable {
    case clear
    case partlyCloudy
    case cloudy
    case fog
    case drizzle
    case rain
    case snow
    case thunderstorm
}
