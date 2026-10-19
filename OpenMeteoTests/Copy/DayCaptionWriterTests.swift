//
//  DayCaptionWriterTests.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic
import Testing
@testable import OpenMeteo

@Suite("Day captions")
@MainActor
struct DayCaptionWriterTests {
    private let writer = DayCaptionWriter()
    private let format = LabelledForecastFormat(timeZone: Fixtures.lisbonTimeZone)
    private let scored = DayAssessment(score: 70, effects: [:])
    private let weather = DailyWeather(
        date: Fixtures.referenceNow,
        condition: .partlyCloudy,
        highCelsius: 23,
        lowCelsius: 16,
        precipitationProbability: 0.1,
        windSpeedKmh: 14,
        windGustsKmh: 24,
        snowfallCm: 3,
        snowDepthCm: nil
    )

    private func caption(_ activity: Activity, assessment: DayAssessment?) -> String {
        writer.caption(for: activity, weather: weather, assessment: assessment, format: format)
    }

    @Test("Captions pick the weather that matters for each activity")
    func activityCaptions() {
        #expect(caption(.surfing, assessment: scored) == String(localized: .captionSurfing("14 kmh", "24 kmh", "10%")))
        #expect(caption(.skiing, assessment: scored) == String(localized: .captionSkiing("3 cm", "23°")))
        #expect(caption(.outdoorSightseeing, assessment: scored) == String(localized: .captionOutdoorSightseeing("10%", "23°")))
        #expect(caption(.indoorSightseeing, assessment: scored) == String(localized: .captionIndoorSightseeing("10%", "24 kmh")))
    }

    @Test("A day without an assessment, or blocked by anything but thunderstorms, keeps the activity's caption", arguments: [
        DayAssessment?.none,
        DayAssessment(blockedBy: .snowfall, effects: [:]),
        DayAssessment(blockedBy: .wind, effects: [:]),
    ])
    func otherBlockers(assessment: DayAssessment?) {
        #expect(caption(.skiing, assessment: assessment) == String(localized: .captionSkiing("3 cm", "23°")))
    }

    @Test("A day blocked by thunderstorms says so with the gusts", arguments: Activity.allCases)
    func thunderstormBlocked(activity: Activity) {
        let blocked = DayAssessment(blockedBy: .thunderstorm, effects: [:])
        #expect(caption(activity, assessment: blocked) == String(localized: .captionBlockedThunderstorm("24 kmh")))
    }
}
