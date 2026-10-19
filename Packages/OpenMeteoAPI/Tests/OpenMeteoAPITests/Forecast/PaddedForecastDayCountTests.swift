//
//  PaddedForecastDayCountTests.swift
//  OpenMeteoAPITests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import OpenMeteoAPI
import Testing

@Suite("Padded forecast day count")
struct PaddedForecastDayCountTests {
    @Test(
        "The standard presets ask for one extra day and never more than sixteen",
        arguments: [(7, 8), (17, 16)]
    )
    func standardDayCount(dayCount: Int, expected: Int) {
        let dayCounts = PaddedForecastDayCount(
            additionalDays: OpenMeteoStandard.additionalForecastDays,
            maximumDays: OpenMeteoStandard.maximumForecastDays
        )
        #expect(dayCounts.requestedDays(forUpcomingDays: dayCount) == expected)
    }

    @Test(
        "Additional days are added to the requested count",
        arguments: [(2, 7, 9)]
    )
    func additionalDays(additionalDays: Int, dayCount: Int, expected: Int) {
        let dayCounts = PaddedForecastDayCount(additionalDays: additionalDays, maximumDays: 16)
        #expect(dayCounts.requestedDays(forUpcomingDays: dayCount) == expected)
    }

    @Test(
        "The maximum caps the requested days",
        arguments: [(5, 7, 5)]
    )
    func maximumDays(maximumDays: Int, dayCount: Int, expected: Int) {
        let dayCounts = PaddedForecastDayCount(additionalDays: 1, maximumDays: maximumDays)
        #expect(dayCounts.requestedDays(forUpcomingDays: dayCount) == expected)
    }
}
