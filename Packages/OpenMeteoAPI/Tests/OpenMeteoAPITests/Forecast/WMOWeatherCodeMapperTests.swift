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
        0: .clear, 2: .partlyCloudy, 3: .cloudy, 45: .fog, 48: .fog, 51: .drizzle, 61: .rain, 71: .snow, 81: .rain, 86: .snow, 96: .thunderstorm,
    ]
    private static let documentedFamilies = [0...3, 45...45, 48...48, 51...57, 61...67, 71...77, 80...82, 85...86, 95...99]
    private static let sweptCodes = -50...300

    private let mapper = WMOWeatherCodeMapper()

    @Test("A documented code from each family maps to that family's condition", arguments: WMOWeatherCodeMapperTests.documentedConditions)
    func documentedCode(code: Int, condition: WeatherCondition) {
        #expect(mapper.condition(forCode: code) == condition)
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
