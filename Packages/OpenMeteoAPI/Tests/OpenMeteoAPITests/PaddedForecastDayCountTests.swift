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
        arguments: [(7, 8), (1, 2), (15, 16), (16, 16), (17, 16), (0, 1), (-1, 1), (Int.min, 1), (Int.max, 16)]
    )
    func standardDayCount(dayCount: Int, expected: Int) {
        let dayCounts = PaddedForecastDayCount(
            additionalDays: OpenMeteoStandard.additionalForecastDays,
            maximumDays: OpenMeteoStandard.maximumForecastDays
        )
        #expect(dayCounts.requestedDays(forUpcomingDays: dayCount) == expected)
    }

    @Test(
        "Additional days are added to the requested count, a negative value counting as none",
        arguments: [(-3, 7, 7), (-3, 0, 1), (Int.min, 7, 7), (0, 7, 7), (0, 0, 1), (2, 7, 9), (2, 15, 16), (16, 0, 16), (Int.max, 0, 16), (Int.max, Int.max, 16)]
    )
    func additionalDays(additionalDays: Int, dayCount: Int, expected: Int) {
        let dayCounts = PaddedForecastDayCount(additionalDays: additionalDays, maximumDays: 16)
        #expect(dayCounts.requestedDays(forUpcomingDays: dayCount) == expected)
    }

    @Test(
        "The maximum caps the requested days, and a maximum below one behaves as one",
        arguments: [(5, 7, 5), (5, 3, 4), (1, 7, 1), (0, 7, 1), (0, 0, 1), (0, Int.max, 1), (-1, 7, 1), (Int.min, 7, 1)]
    )
    func maximumDays(maximumDays: Int, dayCount: Int, expected: Int) {
        let dayCounts = PaddedForecastDayCount(additionalDays: 1, maximumDays: maximumDays)
        #expect(dayCounts.requestedDays(forUpcomingDays: dayCount) == expected)
    }

    @Test(
        "A maximum near Int.max adds the extra days without overflowing",
        arguments: [
            (1, Int.max, Int.max, Int.max),
            (1, Int.max, Int.max - 1, Int.max),
            (1, Int.max, 7, 8),
            (1, Int.max, Int.min, 1),
            (Int.max, Int.max, Int.max, Int.max),
            (Int.max, Int.max, 0, Int.max),
            (2, Int.max - 1, Int.max, Int.max - 1),
        ]
    )
    func unboundedMaximum(additionalDays: Int, maximumDays: Int, dayCount: Int, expected: Int) {
        let dayCounts = PaddedForecastDayCount(additionalDays: additionalDays, maximumDays: maximumDays)
        #expect(dayCounts.requestedDays(forUpcomingDays: dayCount) == expected)
    }
}
