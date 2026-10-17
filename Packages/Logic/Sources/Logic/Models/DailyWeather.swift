//
//  DailyWeather.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation

public struct DailyWeather: Hashable, Codable, Sendable {
    public let date: Date
    public let condition: WeatherCondition
    public let highCelsius: Double
    public let lowCelsius: Double
    public let precipitationProbability: Double?
    public let windSpeedKmh: Double
    public let windGustsKmh: Double
    public let snowfallCm: Double
    public let snowDepthCm: Double?

    public init(
        date: Date,
        condition: WeatherCondition,
        highCelsius: Double,
        lowCelsius: Double,
        precipitationProbability: Double?,
        windSpeedKmh: Double,
        windGustsKmh: Double,
        snowfallCm: Double,
        snowDepthCm: Double?
    ) {
        self.date = date
        self.condition = condition
        self.highCelsius = highCelsius
        self.lowCelsius = lowCelsius
        self.precipitationProbability = precipitationProbability
        self.windSpeedKmh = windSpeedKmh
        self.windGustsKmh = windGustsKmh
        self.snowfallCm = snowfallCm
        self.snowDepthCm = snowDepthCm
    }
}
