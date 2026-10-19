//
//  ForecastEndpoint.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Networking

public struct ForecastEndpoint: Endpoint {
    public typealias Response = ForecastResponseDTO

    public let latitude: Double
    public let longitude: Double
    public let timeZoneIdentifier: String
    public let dayCount: Int

    public init(latitude: Double, longitude: Double, timeZoneIdentifier: String, dayCount: Int) {
        self.latitude = latitude
        self.longitude = longitude
        self.timeZoneIdentifier = timeZoneIdentifier
        self.dayCount = dayCount
    }

    public var method: HTTPMethod { .get }
    public var path: String { "v1/forecast" }

    public var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "daily", value: ForecastDailyField.requestedNames.joined(separator: ",")),
            URLQueryItem(name: "hourly", value: ForecastHourlyField.requestedNames.joined(separator: ",")),
            URLQueryItem(name: "timezone", value: timeZoneIdentifier),
            URLQueryItem(name: "forecast_days", value: String(dayCount)),
        ]
    }
}
