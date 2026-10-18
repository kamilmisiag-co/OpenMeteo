//
//  Fixtures.swift
//  OpenMeteoAPITests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Logic
import Networking
import OpenMeteoAPI
import Testing
import Utils
import UtilsMocks

enum Fixtures {
    enum File: String, CaseIterable {
        case geocodingLisbon = "geocoding_lisbon"
        case geocodingNoMatches = "geocoding_no_matches"
        case geocodingSaoPaulo = "geocoding_sao_paulo"
        case geocodingMissingCountry = "geocoding_missing_country"
        case geocodingErrorCountZero = "geocoding_error_count_zero"
        case forecastZakopane = "forecast_zakopane_tz_europe_warsaw"
        case forecastZakopaneAuto = "forecast_zakopane_tz_auto"
        case forecastZakopaneSixteenDays = "forecast_zakopane_forecast_days_16"
        case forecastAuckland = "forecast_auckland_tz_pacific_auckland"
        case forecastAucklandDefaultGMT = "forecast_auckland_tz_default_gmt"
        case forecastNewYork = "forecast_new_york_tz_america_new_york"
        case forecastLongyearbyen = "forecast_longyearbyen_tz_auto"
        case forecastMunichWithNulls = "forecast_munich_models_icon_d2_with_nulls"
        case forecastErrorBadDailyVariable = "forecast_error_bad_daily_variable"
        case forecastErrorOverloaded = "forecast_error_503_overloaded"
    }

    static let geocodedLisbonCities = [
        City(
            id: 2_267_057, name: "Lisbon", region: "Lisbon District", country: "Portugal", countryCode: "PT",
            latitude: 38.72509, longitude: -9.1498, timeZoneIdentifier: "Europe/Lisbon"
        ),
        City(
            id: 5_160_951, name: "Lisbon", region: "Ohio", country: "United States", countryCode: "US",
            latitude: 40.772, longitude: -80.76813, timeZoneIdentifier: "America/New_York"
        ),
        City(
            id: 5_060_162, name: "Lisbon", region: "North Dakota", country: "United States", countryCode: "US",
            latitude: 46.44163, longitude: -97.68121, timeZoneIdentifier: "America/Chicago"
        ),
        City(
            id: 4_969_622, name: "Lisbon", region: "Maine", country: "United States", countryCode: "US",
            latitude: 44.03146, longitude: -70.1045, timeZoneIdentifier: "America/New_York"
        ),
        City(
            id: 4_864_990, name: "Lisbon", region: "Iowa", country: "United States", countryCode: "US",
            latitude: 41.92112, longitude: -91.38545, timeZoneIdentifier: "America/Chicago"
        ),
        City(
            id: 5_088_728, name: "Lisbon", region: "New Hampshire", country: "United States", countryCode: "US",
            latitude: 44.2134, longitude: -71.91092, timeZoneIdentifier: "America/New_York"
        ),
        City(
            id: 4_584_541, name: "Lamar", region: "South Carolina", country: "United States", countryCode: "US",
            latitude: 34.16877, longitude: -80.06257, timeZoneIdentifier: "America/New_York"
        ),
        City(
            id: 4_360_737, name: "Lisbon", region: "Maryland", country: "United States", countryCode: "US",
            latitude: 39.33622, longitude: -77.07109, timeZoneIdentifier: "America/New_York"
        ),
        City(
            id: 4_331_040, name: "Lisbon", region: "Louisiana", country: "United States", countryCode: "US",
            latitude: 32.79598, longitude: -92.86516, timeZoneIdentifier: "America/Chicago"
        ),
        City(
            id: 5_124_527, name: "Lisbon", region: "New York", country: "United States", countryCode: "US",
            latitude: 44.72728, longitude: -75.32105, timeZoneIdentifier: "America/New_York"
        ),
    ]
    static let zakopane = City(
        id: 3_080_866, name: "Zakopane", region: "Lesser Poland", country: "Poland", countryCode: "PL",
        latitude: 49.2992, longitude: 19.9496, timeZoneIdentifier: "Europe/Warsaw"
    )
    static let noTimeZone = City(
        id: 1, name: "Nowhere", region: nil, country: "Atlantis", countryCode: nil,
        latitude: 0, longitude: 0, timeZoneIdentifier: nil
    )

    static func data(_ file: File) throws -> Data {
        let url = try #require(Bundle.module.url(forResource: file.rawValue, withExtension: "json", subdirectory: "Fixtures"))
        return try Data(contentsOf: url)
    }

    static func decode<Value: Decodable>(_ type: Value.Type, from file: File) throws -> Value {
        try JSONDecoder().decode(type, from: data(file))
    }

    static func decode<Value: Decodable>(_ type: Value.Type, json: String) throws -> Value {
        try JSONDecoder().decode(type, from: Data(json.utf8))
    }

    static func response(_ file: File, status: Int = 200) throws -> HTTPResponse {
        HTTPResponse(statusCode: status, headers: ["Content-Type": "application/json; charset=utf-8"], body: try data(file), url: nil)
    }

    static func localMidnight(_ year: Int, _ month: Int, _ day: Int, in timeZoneIdentifier: String) throws -> Date {
        let timeZone = try #require(TimeZone(identifier: timeZoneIdentifier))
        return try #require(Calendar.gregorian(timeZone: timeZone).date(from: DateComponents(year: year, month: month, day: day)))
    }

    static func baseURL(host: String) throws -> URL {
        try #require(URL(string: "\(OpenMeteoStandard.scheme)://\(host)"))
    }

    static func requestBuilder(host: String) throws -> RequestBuilder {
        RequestBuilder(
            configuration: RequestConfiguration(
                baseURL: try baseURL(host: host),
                defaultHeaders: [:],
                timeout: OpenMeteoStandard.requestTimeout,
                cachePolicy: .useProtocolCachePolicy
            ),
            bodyEncoder: JSONBodyEncoder(encoder: JSONEncoder(), contentType: "application/json")
        )
    }

    static func urlErrorCode(of error: NetworkError?) -> URLError.Code? {
        guard case .transport(let urlError)? = error else { return nil }
        return urlError.code
    }

    static func statusResponse(of error: NetworkError?) -> HTTPResponse? {
        guard case .unacceptableStatusCode(let response)? = error else { return nil }
        return response
    }

    static func retryPolicy(
        randomFraction: @escaping ExponentialBackoffRetryPolicy.RandomFraction = { 1 },
        dateProvider: any DateProviding = ManualDateProvider(now: Date(timeIntervalSince1970: 0))
    ) -> ExponentialBackoffRetryPolicy {
        ExponentialBackoffRetryPolicy(
            maximumRetries: OpenMeteoStandard.maximumRetries,
            initialDelay: OpenMeteoStandard.initialRetryDelay,
            multiplier: OpenMeteoStandard.retryDelayMultiplier,
            maximumDelay: OpenMeteoStandard.maximumRetryDelay,
            jitter: OpenMeteoStandard.retryJitter,
            randomFraction: randomFraction,
            dateProvider: dateProvider,
            retryableMethods: OpenMeteoStandard.retryableMethods,
            retryableStatusCodes: OpenMeteoStandard.retryableStatusCodes,
            retryableURLErrorCodes: OpenMeteoStandard.retryableURLErrorCodes
        )
    }

    static func cityMapper(locale: Locale = Locale(identifier: "en_US_POSIX")) -> GeocodingCityMapper {
        GeocodingCityMapper(regionNames: LocaleRegionNameProvider(locale: locale))
    }

    static func dailyWeatherMapper(
        fallbackTimeZone: TimeZone = .gmt,
        units: ForecastUnits = OpenMeteoStandard.forecastUnits
    ) -> ForecastDailyWeatherMapper {
        ForecastDailyWeatherMapper(
            weatherCodes: WMOWeatherCodeMapper(),
            timeZones: ResponseTimeZoneResolver(fallbackTimeZone: fallbackTimeZone),
            dayKeys: GregorianDayKeyParser(),
            snowDepths: HourlySnowDepthAggregator(),
            units: units
        )
    }

    static func geocodingRequests(localeIdentifier: String = "en_US") -> GeocodingRequestFactory {
        GeocodingRequestFactory(
            resultLimit: OpenMeteoStandard.geocodingResultLimit,
            allowedResultLimits: OpenMeteoStandard.geocodingResultLimits,
            languageCodes: LocaleLanguageCodeProvider(
                locale: Locale(identifier: localeIdentifier),
                fallbackLanguageCode: OpenMeteoStandard.fallbackLanguageCode
            )
        )
    }

    static func forecastRequests(fallbackTimeZoneIdentifier: String = OpenMeteoStandard.timeZoneFallbackIdentifier) -> ForecastRequestFactory {
        ForecastRequestFactory(
            dayCounts: PaddedForecastDayCount(
                additionalDays: OpenMeteoStandard.additionalForecastDays,
                maximumDays: OpenMeteoStandard.maximumForecastDays
            ),
            fallbackTimeZoneIdentifier: fallbackTimeZoneIdentifier
        )
    }

    static func client(host: String, transport: any HTTPTransport, sleeper: any Sleeping) throws -> NetworkClient {
        NetworkClient(
            requestBuilder: try requestBuilder(host: host),
            interceptors: [],
            transport: transport,
            validator: StatusCodeValidator(acceptableStatusCodes: 200..<300),
            decoder: JSONResponseDecoder(decoder: JSONDecoder()),
            retryPolicy: retryPolicy(),
            sleeper: sleeper,
            observers: []
        )
    }
}
