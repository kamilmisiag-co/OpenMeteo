//
//  WMOWeatherCodeMapperTests.swift
//  OpenMeteoAPITests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic
import OpenMeteoAPI
import Testing

@Suite("WMO weather code mapper")
struct WMOWeatherCodeMapperTests {
    private static let documentedConditions: [Int: WeatherCondition] = [
        0: .clear, 1: .clear,
        2: .partlyCloudy,
        3: .cloudy,
        45: .fog, 48: .fog,
        51: .drizzle, 53: .drizzle, 55: .drizzle, 56: .drizzle, 57: .drizzle,
        61: .rain, 63: .rain, 65: .rain, 66: .rain, 67: .rain, 80: .rain, 81: .rain, 82: .rain,
        71: .snow, 73: .snow, 75: .snow, 77: .snow, 85: .snow, 86: .snow,
        95: .thunderstorm, 96: .thunderstorm, 97: .thunderstorm, 99: .thunderstorm,
    ]
    private static let documentedFamilies = [0...3, 45...45, 48...48, 51...57, 61...67, 71...77, 80...82, 85...86, 95...99]
    private static let sweptCodes = -50...300

    private let mapper = WMOWeatherCodeMapper()

    @Test("Every documented code maps to the condition in the table", arguments: WMOWeatherCodeMapperTests.documentedConditions)
    func documentedCode(code: Int, condition: WeatherCondition) {
        #expect(mapper.condition(forCode: code) == condition)
    }

    @Test(
        "Intermediate WMO codes inside a documented family map to that family",
        arguments: [
            (52, WeatherCondition.drizzle), (54, .drizzle),
            (62, .rain), (64, .rain),
            (72, .snow), (74, .snow), (76, .snow),
            (98, .thunderstorm),
        ]
    )
    func intermediateCode(code: Int, condition: WeatherCondition) {
        #expect(mapper.condition(forCode: code) == condition)
    }

    @Test(
        "Undocumented codes map to no condition",
        arguments: [-1, 4, 50, 58, 60, 68, 70, 78, 79, 83, 84, 87, 94, 100, Int.min, Int.max]
    )
    func undocumentedCode(code: Int) {
        #expect(mapper.condition(forCode: code) == nil)
    }

    @Test("No code outside the documented WMO code families maps to a condition")
    func undocumentedSweep() {
        let unexpected = Self.sweptCodes.filter { code in
            !Self.documentedFamilies.contains { $0.contains(code) } && mapper.condition(forCode: code) != nil
        }
        #expect(unexpected.isEmpty)
    }

    @Test("The documented codes reach every weather condition")
    func everyConditionReachable() {
        let reached = Set(Self.sweptCodes.compactMap { mapper.condition(forCode: $0) })
        #expect(reached == Set(WeatherCondition.allCases))
    }
}
