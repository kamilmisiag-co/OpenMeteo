//
//  HourlySnowDepthAggregatorTests.swift
//  OpenMeteoAPITests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import OpenMeteoAPI
import Testing

@Suite("Hourly snow depth aggregator")
struct HourlySnowDepthAggregatorTests {
    private struct SingleDayKey: DayKeyExtracting {
        let key: String

        func dayKey(of timestamp: String) -> String {
            key
        }
    }

    private static let tolerance = 1e-9

    private let aggregator = HourlySnowDepthAggregator()
    private let dayKeys = GregorianDayKeyParser()

    @Test("Each day's depth is its deepest hour in the API's units")
    func maximumPerDay() throws {
        let hourly = try Self.hourly(#"""
        {
          "time": ["2026-10-17T00:00", "2026-10-17T06:00", "2026-10-17T12:00", "2026-10-18T00:00", "2026-10-18T12:00"],
          "snow_depth": [0.05, 0.12, 0.07, 0.2, 0.1]
        }
        """#)
        expectClose(aggregator.dailyMaximumSnowDepth(in: hourly, dayKeys: dayKeys), ["2026-10-17": 0.12, "2026-10-18": 0.2])
    }

    @Test("Longyearbyen's deepest hour per local date stays in metres")
    func longyearbyen() throws {
        let hourly = try Fixtures.decode(ForecastResponseDTO.self, from: .forecastLongyearbyen).hourly
        expectClose(aggregator.dailyMaximumSnowDepth(in: hourly, dayKeys: dayKeys), [
            "2026-10-17": 0.09, "2026-10-18": 0.11, "2026-10-19": 0.17, "2026-10-20": 0.17,
            "2026-10-21": 0.21, "2026-10-22": 0.21, "2026-10-23": 0.2,
        ])
    }

    @Test("Null hours are ignored and a day with only null hours has no depth")
    func nullHours() throws {
        let hourly = try Self.hourly(#"""
        {
          "time": ["2026-10-17T00:00", "2026-10-17T06:00", "2026-10-17T12:00", "2026-10-18T00:00", "2026-10-18T12:00"],
          "snow_depth": [0.05, null, 0.07, null, null]
        }
        """#)
        let depths = aggregator.dailyMaximumSnowDepth(in: hourly, dayKeys: dayKeys)
        expectClose(depths, ["2026-10-17": 0.07])
        #expect(depths["2026-10-18"] == nil)
    }

    @Test("Non-finite hours are ignored")
    func nonFiniteHours() throws {
        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "inf", negativeInfinity: "-inf", nan: "nan")
        let hourly = try decoder.decode(ForecastResponseDTO.Hourly.self, from: Data(#"""
        {
          "time": ["2026-10-17T00:00", "2026-10-17T06:00", "2026-10-17T12:00", "2026-10-18T00:00", "2026-10-18T12:00"],
          "snow_depth": [0.05, "inf", "nan", "-inf", "nan"]
        }
        """#.utf8))
        expectClose(aggregator.dailyMaximumSnowDepth(in: hourly, dayKeys: dayKeys), ["2026-10-17": 0.05])
    }

    @Test("A snow depth array shorter than its hourly times leaves the uncovered days without a depth")
    func shortSnowDepth() throws {
        let hourly = try Self.hourly(#"""
        {"time": ["2026-10-17T00:00", "2026-10-17T12:00", "2026-10-18T00:00", "2026-10-18T12:00"], "snow_depth": [0.12, 0.1]}
        """#)
        expectClose(aggregator.dailyMaximumSnowDepth(in: hourly, dayKeys: dayKeys), ["2026-10-17": 0.12])
    }

    @Test("A snow depth array longer than its hourly times ignores the extra values")
    func longSnowDepth() throws {
        let hourly = try Self.hourly(#"{"time": ["2026-10-17T00:00"], "snow_depth": [0.12, 0.5, 0.9]}"#)
        expectClose(aggregator.dailyMaximumSnowDepth(in: hourly, dayKeys: dayKeys), ["2026-10-17": 0.12])
    }

    @Test("An hourly block without snow depth is rejected when decoding")
    func missingSnowDepth() {
        #expect(throws: DecodingError.self) {
            try Self.hourly(#"{"time": ["2026-10-17T00:00", "2026-10-18T00:00"]}"#)
        }
    }

    @Test("Hours are grouped by the day key extractor passed to each call", arguments: ["everything", "2026-10-17"])
    func injectedDayKeys(key: String) throws {
        let hourly = try Self.hourly(#"""
        {"time": ["2026-10-17T00:00", "2026-10-18T00:00", "2026-10-19T00:00"], "snow_depth": [0.05, 0.3, 0.1]}
        """#)
        expectClose(aggregator.dailyMaximumSnowDepth(in: hourly, dayKeys: SingleDayKey(key: key)), [key: 0.3])
        expectClose(aggregator.dailyMaximumSnowDepth(in: hourly, dayKeys: dayKeys), ["2026-10-17": 0.05, "2026-10-18": 0.3, "2026-10-19": 0.1])
    }

    private func expectClose(_ depths: [String: Double], _ expected: [String: Double], sourceLocation: SourceLocation = #_sourceLocation) {
        #expect(Set(depths.keys) == Set(expected.keys), sourceLocation: sourceLocation)
        for (key, value) in expected {
            #expect(depths[key].map { abs($0 - value) < Self.tolerance } == true, sourceLocation: sourceLocation)
        }
    }

    private static func hourly(_ json: String) throws -> ForecastResponseDTO.Hourly {
        try Fixtures.decode(ForecastResponseDTO.Hourly.self, json: json)
    }
}
