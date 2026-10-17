//
//  ForecastDailyWeatherMapperTests.swift
//  OpenMeteoAPITests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Logic
import OpenMeteoAPI
import Synchronization
import Testing
import Utils

@Suite("Forecast daily weather mapper")
struct ForecastDailyWeatherMapperTests {
    private struct FogUnlessClear: WeatherCodeMapping {
        func condition(forCode code: Int) -> WeatherCondition? {
            code == 0 ? nil : .fog
        }
    }

    private final class RecordingTimeZones: ForecastTimeZoneResolving {
        private let zone: TimeZone
        private let received = Mutex<[ForecastResponseDTO]>([])

        init(_ zone: TimeZone) {
            self.zone = zone
        }

        var receivedResponses: [ForecastResponseDTO] {
            received.withLock { $0 }
        }

        func timeZone(of response: ForecastResponseDTO) -> TimeZone {
            received.withLock { $0.append(response) }
            return zone
        }
    }

    private final class RecordingDayKeys: DayKeyExtracting, LocalMidnightParsing {
        struct Lookup: Equatable {
            let dayKey: String
            let timeZone: TimeZone
        }

        private let midnights: [String: Date]
        private let lookups = Mutex<[Lookup]>([])

        init(midnights: [String: Date]) {
            self.midnights = midnights
        }

        var recordedLookups: [Lookup] {
            lookups.withLock { $0 }
        }

        func dayKey(of timestamp: String) -> String {
            "day \(timestamp)"
        }

        func localMidnight(ofDayKey dayKey: String, in timeZone: TimeZone) -> Date? {
            lookups.withLock { $0.append(Lookup(dayKey: dayKey, timeZone: timeZone)) }
            return midnights[dayKey]
        }
    }

    private final class RecordingSnowDepths: SnowDepthAggregating {
        struct Call {
            let hourly: ForecastResponseDTO.Hourly
            let dayKeys: any DayKeyExtracting
        }

        private let depths: [String: Double]
        private let received = Mutex<[Call]>([])

        init(_ depths: [String: Double] = [:]) {
            self.depths = depths
        }

        var receivedHourly: [ForecastResponseDTO.Hourly] {
            received.withLock { $0.map(\.hourly) }
        }

        var receivedDayKeys: [any DayKeyExtracting] {
            received.withLock { $0.map(\.dayKeys) }
        }

        func dailyMaximumSnowDepth(in hourly: ForecastResponseDTO.Hourly, dayKeys: any DayKeyExtracting) -> [String: Double] {
            received.withLock { $0.append(Call(hourly: hourly, dayKeys: dayKeys)) }
            return depths
        }
    }

    private static let tolerance = 1e-9
    private static let syntheticTimeZone = "Europe/Warsaw"
    private static let wideHourly = #"""
    {"time": ["2026-10-17T00:00", "2026-10-18T00:00"], "snow_depth": [0.9, 0.9]}
    """#
    private static let snowlessHourly = #"""
    {"time": ["2026-10-17T00:00", "2026-10-17T12:00", "2026-10-18T00:00", "2026-10-18T12:00"], "snow_depth": [null, null, null, null]}
    """#

    private let mapper = Fixtures.dailyWeatherMapper()

    @Test("Zakopane days start at local midnight in Europe/Warsaw, two hours ahead of UTC")
    func zakopaneMidnights() throws {
        let dates = try mapped(.forecastZakopane).map(\.date)
        let expected = try (17...23).map { try Fixtures.localMidnight(2026, 10, $0, in: "Europe/Warsaw") }
        let firstInstant = try Self.instant("2026-10-16T22:00:00Z")
        #expect(dates == expected)
        #expect(dates.first == firstInstant)
    }

    @Test("New York days start at local midnight in America/New_York, four hours behind UTC")
    func newYorkMidnights() throws {
        let dates = try mapped(.forecastNewYork).map(\.date)
        let expected = try (17...23).map { try Fixtures.localMidnight(2026, 10, $0, in: "America/New_York") }
        let firstInstant = try Self.instant("2026-10-17T04:00:00Z")
        #expect(dates == expected)
        #expect(dates.first == firstInstant)
    }

    @Test("Auckland's first day is local 2026-10-18, which starts at 11:00 UTC on 2026-10-17")
    func aucklandMidnights() throws {
        let dates = try mapped(.forecastAuckland).map(\.date)
        let expected = try (18...24).map { try Fixtures.localMidnight(2026, 10, $0, in: "Pacific/Auckland") }
        let firstInstant = try Self.instant("2026-10-17T11:00:00Z")
        #expect(dates == expected)
        #expect(dates.first == firstInstant)
    }

    @Test("Sixteen Zakopane days stay at sixteen distinct local midnights across the end of summer time")
    func daylightSavingTransition() throws {
        let warsaw = Calendar.gregorian(timeZone: try #require(TimeZone(identifier: "Europe/Warsaw")))
        let dates = try mapped(.forecastZakopaneSixteenDays).map(\.date)
        let october = try (17...31).map { try Fixtures.localMidnight(2026, 10, $0, in: "Europe/Warsaw") }
        let expected = october + [try Fixtures.localMidnight(2026, 11, 1, in: "Europe/Warsaw")]
        let lastSummerMidnight = try Self.instant("2026-10-24T22:00:00Z")
        let firstWinterMidnight = try Self.instant("2026-10-25T23:00:00Z")
        try #require(dates.count == 16)
        #expect(dates == expected)
        #expect(Set(dates.map { warsaw.startOfDay(for: $0) }).count == 16)
        #expect(dates.allSatisfy { warsaw.startOfDay(for: $0) == $0 })
        #expect(dates[8] == lastSummerMidnight)
        #expect(dates[9] == firstWinterMidnight)
        #expect(dates[9].timeIntervalSince(dates[8]) == 25 * 60 * 60)
    }

    @Test("Munich icon_d2 nulls keep only the two days that have every required value")
    func munichNulls() throws {
        let days = try mapped(.forecastMunichWithNulls)
        try #require(days.count == 2)
        expectDay(days[0], equals: DailyWeather(
            date: try Fixtures.localMidnight(2026, 10, 17, in: "Europe/Berlin"), condition: .rain, highCelsius: 15.0, lowCelsius: 9.9,
            precipitationProbability: 0.3, windSpeedKmh: 11.5, windGustsKmh: 25.6, snowfallCm: 0.0, snowDepthCm: 0.0
        ))
        expectDay(days[1], equals: DailyWeather(
            date: try Fixtures.localMidnight(2026, 10, 18, in: "Europe/Berlin"), condition: .rain, highCelsius: 16.7, lowCelsius: 9.2,
            precipitationProbability: 0.6, windSpeedKmh: 10.2, windGustsKmh: 27.7, snowfallCm: 0.0, snowDepthCm: 0.0
        ))
    }

    @Test("Longyearbyen days carry the converted snow, wind and precipitation values")
    func longyearbyenValues() throws {
        let days = try mapped(.forecastLongyearbyen)
        try #require(days.count == 7)
        expectDay(days[0], equals: DailyWeather(
            date: try Fixtures.localMidnight(2026, 10, 17, in: "Arctic/Longyearbyen"), condition: .snow, highCelsius: -1.0, lowCelsius: -7.1,
            precipitationProbability: 1.0, windSpeedKmh: 19.8, windGustsKmh: 55.1, snowfallCm: 2.45, snowDepthCm: 9.0
        ))
        expectDay(days[2], equals: DailyWeather(
            date: try Fixtures.localMidnight(2026, 10, 19, in: "Arctic/Longyearbyen"), condition: .rain, highCelsius: 3.5, lowCelsius: -0.3,
            precipitationProbability: 1.0, windSpeedKmh: 22.8, windGustsKmh: 82.4, snowfallCm: 0.21, snowDepthCm: 17.0
        ))
        expectDay(days[4], equals: DailyWeather(
            date: try Fixtures.localMidnight(2026, 10, 21, in: "Arctic/Longyearbyen"), condition: .snow, highCelsius: 3.4, lowCelsius: -9.1,
            precipitationProbability: 0.86, windSpeedKmh: 9.9, windGustsKmh: 31.0, snowfallCm: 4.13, snowDepthCm: 21.0
        ))
        expectDay(days[5], equals: DailyWeather(
            date: try Fixtures.localMidnight(2026, 10, 22, in: "Arctic/Longyearbyen"), condition: .drizzle, highCelsius: 4.0, lowCelsius: 0.5,
            precipitationProbability: 0.59, windSpeedKmh: 9.8, windGustsKmh: 28.4, snowfallCm: 0.0, snowDepthCm: 21.0
        ))
    }

    @Test("Longyearbyen snow depth is the deepest hour of each local date in centimetres")
    func longyearbyenSnowDepths() throws {
        let days = try mapped(.forecastLongyearbyen)
        #expect(days.map(\.condition) == [.snow, .snow, .rain, .snow, .snow, .drizzle, .drizzle])
        #expect(days.map(\.snowfallCm) == [2.45, 3.15, 0.21, 0.28, 4.13, 0.0, 0.0])
        expectClose(days.map(\.snowDepthCm), [9.0, 11.0, 17.0, 17.0, 21.0, 21.0, 20.0])
    }

    @Test("Without a timezone parameter the API answers in GMT, so Auckland's first day is already yesterday there")
    func defaultGMT() throws {
        let auckland = Calendar.gregorian(timeZone: try #require(TimeZone(identifier: "Pacific/Auckland")))
        let gmtFirst = try #require(try mapped(.forecastAucklandDefaultGMT).first?.date)
        let localFirst = try #require(try mapped(.forecastAuckland).first?.date)
        let gmtMidnight = try Self.instant("2026-10-17T00:00:00Z")
        let aucklandMidnight = try Self.instant("2026-10-17T11:00:00Z")
        #expect(gmtFirst == gmtMidnight)
        #expect(localFirst == aucklandMidnight)
        #expect(auckland.dateComponents([.year, .month, .day], from: gmtFirst) == DateComponents(year: 2026, month: 10, day: 17))
        #expect(auckland.dateComponents([.year, .month, .day], from: localFirst) == DateComponents(year: 2026, month: 10, day: 18))
    }

    @Test("The auto and explicit time zone responses for Zakopane map to the same days")
    func autoMatchesExplicit() throws {
        let explicit = try mapped(.forecastZakopane)
        let auto = try mapped(.forecastZakopaneAuto)
        #expect(explicit.count == 7)
        #expect(auto == explicit)
    }

    @Test("A complete synthetic forecast maps every field of every day")
    func completeSyntheticForecast() throws {
        let days = try mapped(json: Self.twoDayJSON())
        let expected = try Self.syntheticDays()
        try #require(days.count == 2)
        expectDay(days[0], equals: expected[0])
        expectDay(days[1], equals: expected[1])
    }

    @Test(
        "A null or missing precipitation probability keeps the day without a probability",
        arguments: [
            ("[null, 85]", [nil, 0.85]),
            ("[0]", [0.0, nil]),
            ("[]", [nil, nil]),
            ("[null, null]", [nil, nil]),
        ] as [(String, [Double?])]
    )
    func missingPrecipitationProbability(values: String, expected: [Double?]) throws {
        let days = try mapped(json: Self.twoDayJSON(overriding: ["precipitation_probability_max": values]))
        let synthetic = try Self.syntheticDays()
        #expect(days.map(\.date) == synthetic.map(\.date))
        expectClose(days.map(\.precipitationProbability), expected)
    }

    @Test(
        "Precipitation probability is a fraction clamped to zero through one",
        arguments: [("100", 1.0), ("150", 1.0), ("100.5", 1.0), ("0", 0.0), ("45", 0.45), ("-5", 0.0)]
    )
    func precipitationFraction(percent: String, expected: Double) throws {
        let days = try mapped(json: Self.twoDayJSON(overriding: ["precipitation_probability_max": "[\(percent), 85]"]))
        try #require(days.count == 2)
        expectClose([days[0].precipitationProbability], [expected])
    }

    @Test(
        "A required daily array shorter than time skips the days it does not cover",
        arguments: [
            ("weather_code", "[0]"),
            ("temperature_2m_max", "[13.1]"),
            ("temperature_2m_min", "[2.5]"),
            ("wind_speed_10m_max", "[7.6]"),
            ("wind_gusts_10m_max", "[15.1]"),
            ("snowfall_sum", "[0.0]"),
        ]
    )
    func shortDailyArray(key: String, values: String) throws {
        let days = try mapped(json: Self.twoDayJSON(overriding: [key: values]))
        let synthetic = try Self.syntheticDays()
        try #require(days.count == 1)
        expectDay(days[0], equals: synthetic[0])
    }

    @Test(
        "A null required daily value skips that day only",
        arguments: [
            ("weather_code", "[null, 61]"),
            ("temperature_2m_max", "[null, 12.0]"),
            ("temperature_2m_min", "[null, -1.5]"),
            ("wind_speed_10m_max", "[null, 21.4]"),
            ("wind_gusts_10m_max", "[null, 48.3]"),
            ("snowfall_sum", "[null, 1.2]"),
        ]
    )
    func nullDailyValue(key: String, values: String) throws {
        let days = try mapped(json: Self.twoDayJSON(overriding: [key: values]))
        let synthetic = try Self.syntheticDays()
        try #require(days.count == 1)
        expectDay(days[0], equals: synthetic[1])
    }

    @Test("A daily block without its requested variables is rejected before mapping")
    func onlyTime() {
        #expect(throws: DecodingError.self) {
            try mapped(json: #"{"timezone": "Europe/Warsaw", "daily": {"time": ["2026-10-17", "2026-10-18"]}, "hourly": \#(Self.snowlessHourly)}"#)
        }
    }

    @Test("Units that make a probability non-finite leave the probability unknown")
    func nonFiniteProbability() throws {
        let units = ForecastUnits(percentPerFraction: 0, centimetresPerSnowDepthUnit: 100)
        let days = Self.composedMapper(units: units).dailyWeather(from: try Self.response(json: Self.twoDayJSON()))
        try #require(days.count == 2)
        #expect(days.map(\.precipitationProbability) == [nil, nil])
    }

    @Test("A snow depth that overflows on conversion leaves the snow depth unknown")
    func nonFiniteSnowDepth() throws {
        let hourly = #"{"time": ["2026-10-17T00:00", "2026-10-18T00:00"], "snow_depth": [0.2, 1e308]}"#
        let response = try Self.response(json: Self.twoDayJSON(hourly: hourly))
        let days = Fixtures.dailyWeatherMapper().dailyWeather(from: response)
        try #require(days.count == 2)
        let found = try #require(days[0].snowDepthCm)
        #expect(Self.isClose(found, 20))
        #expect(days[1].snowDepthCm == nil)
    }

    @Test("An unknown weather code skips the day", arguments: [4, 58, 100, -1])
    func unknownWeatherCode(code: Int) throws {
        let days = try mapped(json: Self.twoDayJSON(overriding: ["weather_code": "[\(code), 61]"]))
        let synthetic = try Self.syntheticDays()
        try #require(days.count == 1)
        expectDay(days[0], equals: synthetic[1])
    }

    @Test(
        "A response without a daily block is rejected before mapping",
        arguments: [
            #"{"timezone": "Europe/Warsaw"}"#,
            #"{"timezone": "Europe/Warsaw", "hourly": {"time": ["2026-10-17T00:00"], "snow_depth": [0.1]}}"#,
        ]
    )
    func missingDaily(json: String) {
        #expect(throws: DecodingError.self) {
            try mapped(json: json)
        }
    }

    @Test("The injected weather code mapping decides each day's condition")
    func injectedWeatherCodes() throws {
        let response = try Self.response(json: Self.twoDayJSON())
        let days = Self.composedMapper(weatherCodes: FogUnlessClear()).dailyWeather(from: response)
        let synthetic = try Self.syntheticDays()
        #expect(days.map(\.date) == [synthetic[1].date])
        #expect(days.map(\.condition) == [.fog])
    }

    @Test("Every date is local midnight in the zone from the injected resolver", arguments: ["Asia/Tokyo", "America/Los_Angeles"])
    func injectedTimeZone(identifier: String) throws {
        let zone = try #require(TimeZone(identifier: identifier))
        let response = try Self.response(json: Self.twoDayJSON())
        let timeZones = RecordingTimeZones(zone)
        let days = Self.composedMapper(timeZones: timeZones).dailyWeather(from: response)
        let expected = try [17, 18].map { try Fixtures.localMidnight(2026, 10, $0, in: identifier) }
        #expect(days.map(\.date) == expected)
        #expect(timeZones.receivedResponses == [response])
    }

    @Test("Dates come from the injected day key parser, asked with its own day keys in the resolved zone")
    func injectedDayKeys() throws {
        let tokyo = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let first = Date(timeIntervalSince1970: 1_000_000)
        let second = Date(timeIntervalSince1970: 2_000_000)
        let dayKeys = RecordingDayKeys(midnights: ["day 2026-10-17": first, "day 2026-10-18": second])
        let response = try Self.response(json: Self.twoDayJSON())
        let days = Self.composedMapper(timeZones: RecordingTimeZones(tokyo), dayKeys: dayKeys).dailyWeather(from: response)
        let synthetic = try Self.syntheticDays()
        try #require(days.count == 2)
        expectDay(days[0], equals: Self.day(synthetic[0], date: first))
        expectDay(days[1], equals: Self.day(synthetic[1], date: second))
        #expect(dayKeys.recordedLookups == [
            RecordingDayKeys.Lookup(dayKey: "day 2026-10-17", timeZone: tokyo),
            RecordingDayKeys.Lookup(dayKey: "day 2026-10-18", timeZone: tokyo),
        ])
    }

    @Test("A day the injected parser rejects is skipped")
    func rejectedDay() throws {
        let second = Date(timeIntervalSince1970: 2_000_000)
        let dayKeys = RecordingDayKeys(midnights: ["day 2026-10-18": second])
        let days = Self.composedMapper(dayKeys: dayKeys).dailyWeather(from: try Self.response(json: Self.twoDayJSON()))
        let synthetic = try Self.syntheticDays()
        try #require(days.count == 1)
        expectDay(days[0], equals: Self.day(synthetic[1], date: second))
    }

    @Test(
        "Snow depth comes from the injected aggregator, scaled by the injected centimetres per depth unit",
        arguments: [(10.0, 2.5), (100.0, 25.0)]
    )
    func injectedSnowDepths(centimetresPerUnit: Double, expected: Double) throws {
        let response = try Self.response(json: Self.twoDayJSON(hourly: Self.wideHourly))
        let snowDepths = RecordingSnowDepths(["2026-10-18": 0.25])
        let units = ForecastUnits(percentPerFraction: 50, centimetresPerSnowDepthUnit: centimetresPerUnit)
        let days = Self.composedMapper(snowDepths: snowDepths, units: units).dailyWeather(from: response)
        try #require(days.count == 2)
        expectClose(days.map(\.snowDepthCm), [nil, expected])
        #expect(snowDepths.receivedHourly == [response.hourly])
    }

    @Test("Snow depth is looked up by the injected parser's day key")
    func snowDepthKeyedByParser() throws {
        let dayKeys = RecordingDayKeys(midnights: [
            "day 2026-10-17": Date(timeIntervalSince1970: 1_000_000),
            "day 2026-10-18": Date(timeIntervalSince1970: 2_000_000),
        ])
        let snowDepths = RecordingSnowDepths(["day 2026-10-18": 0.25, "2026-10-17": 0.5])
        let days = Self.composedMapper(dayKeys: dayKeys, snowDepths: snowDepths).dailyWeather(from: try Self.response(json: Self.twoDayJSON()))
        expectClose(days.map(\.snowDepthCm), [nil, 25.0])
    }

    @Test("The aggregator groups hours with the mapper's own day key parser")
    func aggregatorReceivesMapperDayKeys() throws {
        let dayKeys = RecordingDayKeys(midnights: [:])
        let snowDepths = RecordingSnowDepths()
        let response = try Self.response(json: Self.twoDayJSON(hourly: Self.wideHourly))
        _ = Self.composedMapper(dayKeys: dayKeys, snowDepths: snowDepths).dailyWeather(from: response)
        let received = snowDepths.receivedDayKeys
        try #require(received.count == 1)
        #expect((received[0] as? RecordingDayKeys) === dayKeys)
        #expect(received[0].dayKey(of: "2026-10-17T05:00") == "day 2026-10-17T05:00")
        #expect(snowDepths.receivedHourly == [response.hourly])
    }

    @Test(
        "Precipitation probability is divided by the injected percent per fraction",
        arguments: [(50.0, [0.4, 0.8]), (100.0, [0.2, 0.4]), (25.0, [0.8, 1.0])] as [(Double, [Double?])]
    )
    func injectedPercentPerFraction(percentPerFraction: Double, expected: [Double?]) throws {
        let response = try Self.response(json: Self.twoDayJSON(overriding: ["precipitation_probability_max": "[20, 40]"]))
        let units = ForecastUnits(percentPerFraction: percentPerFraction, centimetresPerSnowDepthUnit: 10)
        let days = Self.composedMapper(units: units).dailyWeather(from: response)
        expectClose(days.map(\.precipitationProbability), expected)
    }

    private func mapped(_ file: Fixtures.File) throws -> [DailyWeather] {
        mapper.dailyWeather(from: try Fixtures.decode(ForecastResponseDTO.self, from: file))
    }

    private func mapped(json: String) throws -> [DailyWeather] {
        mapper.dailyWeather(from: try Self.response(json: json))
    }

    private func expectDay(_ day: DailyWeather, equals expected: DailyWeather, sourceLocation: SourceLocation = #_sourceLocation) {
        #expect(day.date == expected.date, sourceLocation: sourceLocation)
        #expect(day.condition == expected.condition, sourceLocation: sourceLocation)
        #expect(day.highCelsius == expected.highCelsius, sourceLocation: sourceLocation)
        #expect(day.lowCelsius == expected.lowCelsius, sourceLocation: sourceLocation)
        #expect(Self.isClose(day.precipitationProbability, expected.precipitationProbability), sourceLocation: sourceLocation)
        #expect(day.windSpeedKmh == expected.windSpeedKmh, sourceLocation: sourceLocation)
        #expect(day.windGustsKmh == expected.windGustsKmh, sourceLocation: sourceLocation)
        #expect(day.snowfallCm == expected.snowfallCm, sourceLocation: sourceLocation)
        #expect(Self.isClose(day.snowDepthCm, expected.snowDepthCm), sourceLocation: sourceLocation)
    }

    private func expectClose(_ values: [Double?], _ expected: [Double?], sourceLocation: SourceLocation = #_sourceLocation) {
        #expect(values.count == expected.count, sourceLocation: sourceLocation)
        for (value, expectedValue) in zip(values, expected) {
            #expect(Self.isClose(value, expectedValue), sourceLocation: sourceLocation)
        }
    }

    private static func composedMapper(
        weatherCodes: any WeatherCodeMapping = WMOWeatherCodeMapper(),
        timeZones: any ForecastTimeZoneResolving = ResponseTimeZoneResolver(fallbackTimeZone: .gmt),
        dayKeys: any DayKeyExtracting & LocalMidnightParsing = GregorianDayKeyParser(),
        snowDepths: any SnowDepthAggregating = RecordingSnowDepths(),
        units: ForecastUnits = OpenMeteoStandard.forecastUnits
    ) -> ForecastDailyWeatherMapper {
        ForecastDailyWeatherMapper(
            weatherCodes: weatherCodes,
            timeZones: timeZones,
            dayKeys: dayKeys,
            snowDepths: snowDepths,
            units: units
        )
    }

    private static func isClose(_ lhs: Double?, _ rhs: Double?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil): true
        case let (lhs?, rhs?): abs(lhs - rhs) < tolerance
        default: false
        }
    }

    private static func instant(_ text: String) throws -> Date {
        try Date(text, strategy: .iso8601)
    }

    private static func response(json: String) throws -> ForecastResponseDTO {
        try Fixtures.decode(ForecastResponseDTO.self, json: json)
    }

    private static func day(_ day: DailyWeather, date: Date) -> DailyWeather {
        DailyWeather(
            date: date, condition: day.condition, highCelsius: day.highCelsius, lowCelsius: day.lowCelsius,
            precipitationProbability: day.precipitationProbability, windSpeedKmh: day.windSpeedKmh, windGustsKmh: day.windGustsKmh,
            snowfallCm: day.snowfallCm, snowDepthCm: day.snowDepthCm
        )
    }

    private static func syntheticDays() throws -> [DailyWeather] {
        [
            DailyWeather(
                date: try Fixtures.localMidnight(2026, 10, 17, in: syntheticTimeZone), condition: .clear, highCelsius: 13.1, lowCelsius: 2.5,
                precipitationProbability: 0.0, windSpeedKmh: 7.6, windGustsKmh: 15.1, snowfallCm: 0.0, snowDepthCm: nil
            ),
            DailyWeather(
                date: try Fixtures.localMidnight(2026, 10, 18, in: syntheticTimeZone), condition: .rain, highCelsius: 12.0, lowCelsius: -1.5,
                precipitationProbability: 0.85, windSpeedKmh: 21.4, windGustsKmh: 48.3, snowfallCm: 1.2, snowDepthCm: nil
            ),
        ]
    }

    private static func twoDayJSON(
        overriding overrides: [String: String] = [:],
        hourly: String = snowlessHourly
    ) -> String {
        let daily = [
            ("time", #"["2026-10-17", "2026-10-18"]"#),
            ("weather_code", "[0, 61]"),
            ("temperature_2m_max", "[13.1, 12.0]"),
            ("temperature_2m_min", "[2.5, -1.5]"),
            ("precipitation_probability_max", "[0, 85]"),
            ("wind_speed_10m_max", "[7.6, 21.4]"),
            ("wind_gusts_10m_max", "[15.1, 48.3]"),
            ("snowfall_sum", "[0.0, 1.2]"),
        ].map { key, values in #""\#(key)": \#(overrides[key] ?? values)"# }
        return #"{"timezone": "\#(syntheticTimeZone)", "daily": {\#(daily.joined(separator: ", "))}, "hourly": \#(hourly)}"#
    }
}
