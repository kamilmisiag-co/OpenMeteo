//
//  OpenMeteoStandard.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Networking

public enum OpenMeteoStandard {
    public static let geocodingBaseURL = URL(string: "https://geocoding-api.open-meteo.com")!
    public static let forecastBaseURL = URL(string: "https://api.open-meteo.com")!
    public static let requestTimeout = Duration.seconds(15)
    public static let geocodingResultLimit = 10
    public static let fallbackLanguageCode = "en"
    public static let additionalForecastDays = 1
    public static let maximumForecastDays = 16
    public static let forecastUnits = ForecastUnits(percentPerFraction: 100, centimetresPerSnowDepthUnit: 100)
    public static let maximumRetries = 2
    public static let initialRetryDelay = Duration.milliseconds(500)
    public static let retryDelayMultiplier = 2.0
    public static let maximumRetryDelay = Duration.seconds(8)
    public static let retryJitter = BackoffJitter.equal
    public static let retryableMethods: Set<HTTPMethod> = [.get]
    public static let retryableStatusCodes: Set<Int> = [408, 429, 500, 502, 503, 504]
    public static let retryableURLErrorCodes: Set<URLError.Code> = [.networkConnectionLost]
}
