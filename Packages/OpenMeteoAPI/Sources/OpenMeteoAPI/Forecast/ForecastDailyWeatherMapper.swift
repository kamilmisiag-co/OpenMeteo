//
//  ForecastDailyWeatherMapper.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Logic
import Utils

public protocol DailyWeatherMapping: Sendable {
    func dailyWeather(from response: ForecastResponseDTO) -> [DailyWeather]
}

public struct ForecastDailyWeatherMapper: DailyWeatherMapping {
    private let weatherCodes: any WeatherCodeMapping
    private let timeZones: any ForecastTimeZoneResolving
    private let dayKeys: any DayKeyExtracting & LocalMidnightParsing
    private let snowDepths: any SnowDepthAggregating
    private let units: ForecastUnits

    public init(
        weatherCodes: any WeatherCodeMapping,
        timeZones: any ForecastTimeZoneResolving,
        dayKeys: any DayKeyExtracting & LocalMidnightParsing,
        snowDepths: any SnowDepthAggregating,
        units: ForecastUnits
    ) {
        self.weatherCodes = weatherCodes
        self.timeZones = timeZones
        self.dayKeys = dayKeys
        self.snowDepths = snowDepths
        self.units = units
    }

    public func dailyWeather(from response: ForecastResponseDTO) -> [DailyWeather] {
        let timeZone = timeZones.timeZone(of: response)
        let depths = snowDepths.dailyMaximumSnowDepth(in: response.hourly, dayKeys: dayKeys)
        return response.daily.time.indices.compactMap { index in
            day(at: index, in: response.daily, timeZone: timeZone, snowDepths: depths)
        }
    }

    private func day(
        at index: Int,
        in daily: ForecastResponseDTO.Daily,
        timeZone: TimeZone,
        snowDepths: [String: Double]
    ) -> DailyWeather? {
        let dayKey = dayKeys.dayKey(of: daily.time[index])
        guard let date = dayKeys.localMidnight(ofDayKey: dayKey, in: timeZone),
              let code = element(at: index, of: daily.weatherCode),
              let condition = weatherCodes.condition(forCode: code),
              let high = element(at: index, of: daily.temperatureMax),
              let low = element(at: index, of: daily.temperatureMin),
              let windSpeed = element(at: index, of: daily.windSpeedMax),
              let windGusts = element(at: index, of: daily.windGustsMax),
              let snowfall = element(at: index, of: daily.snowfallSum) else { return nil }
        return DailyWeather(
            date: date,
            condition: condition,
            highCelsius: high,
            lowCelsius: low,
            precipitationProbability: element(at: index, of: daily.precipitationProbabilityMax).flatMap(probability(fromPercent:)),
            windSpeedKmh: windSpeed,
            windGustsKmh: windGusts,
            snowfallCm: snowfall,
            snowDepthCm: snowDepths[dayKey].flatMap(centimetres(fromSnowDepth:))
        )
    }

    private func probability(fromPercent percent: Double) -> Double? {
        (percent / units.percentPerFraction).finiteValue?.clamped(to: 0...1)
    }

    private func centimetres(fromSnowDepth depth: Double) -> Double? {
        (depth * units.centimetresPerSnowDepthUnit).finiteValue
    }

    private func element<Value>(at index: Int, of values: [Value?]) -> Value? {
        values.element(at: index) ?? nil
    }
}
