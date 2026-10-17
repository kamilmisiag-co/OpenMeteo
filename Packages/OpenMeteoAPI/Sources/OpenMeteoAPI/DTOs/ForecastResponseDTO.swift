//
//  ForecastResponseDTO.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

public struct ForecastResponseDTO: Decodable, Hashable, Sendable {
    public struct Daily: Decodable, Hashable, Sendable {
        public let time: [String]
        public let weatherCode: [Int?]
        public let temperatureMax: [Double?]
        public let temperatureMin: [Double?]
        public let precipitationProbabilityMax: [Double?]
        public let windSpeedMax: [Double?]
        public let windGustsMax: [Double?]
        public let snowfallSum: [Double?]

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: ForecastDailyField.self)
            time = try container.decode([String].self, forKey: .time)
            weatherCode = try container.decode([Int?].self, forKey: .weatherCode)
            temperatureMax = try container.decode([Double?].self, forKey: .temperatureMax)
            temperatureMin = try container.decode([Double?].self, forKey: .temperatureMin)
            precipitationProbabilityMax = try container.decode([Double?].self, forKey: .precipitationProbabilityMax)
            windSpeedMax = try container.decode([Double?].self, forKey: .windSpeedMax)
            windGustsMax = try container.decode([Double?].self, forKey: .windGustsMax)
            snowfallSum = try container.decode([Double?].self, forKey: .snowfallSum)
        }
    }

    public struct Hourly: Decodable, Hashable, Sendable {
        public let time: [String]
        public let snowDepth: [Double?]

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: ForecastHourlyField.self)
            time = try container.decode([String].self, forKey: .time)
            snowDepth = try container.decode([Double?].self, forKey: .snowDepth)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case timezone
        case daily
        case hourly
    }

    public let timezone: String
    public let daily: Daily
    public let hourly: Hourly
}
