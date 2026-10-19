//
//  ForecastResponseDTO.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

public struct ForecastResponseDTO: Decodable, Hashable, Sendable {
    public struct Daily: Decodable, Hashable, Sendable {
        private typealias CodingKeys = ForecastDailyField

        public let time: [String]
        public let weatherCode: [Int?]
        public let temperatureMax: [Double?]
        public let temperatureMin: [Double?]
        public let precipitationProbabilityMax: [Double?]
        public let windSpeedMax: [Double?]
        public let windGustsMax: [Double?]
        public let snowfallSum: [Double?]
    }

    public struct Hourly: Decodable, Hashable, Sendable {
        private typealias CodingKeys = ForecastHourlyField

        public let time: [String]
        public let snowDepth: [Double?]
    }

    public let timezone: String
    public let daily: Daily
    public let hourly: Hourly
}
