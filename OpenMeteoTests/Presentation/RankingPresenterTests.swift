//
//  RankingPresenterTests.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import DesignSystem
import Foundation
import Logic
import Testing
import Utils
@testable import OpenMeteo

@Suite("Ranking presenter")
@MainActor
struct RankingPresenterTests {
    private static let ranking = [
        RankedActivity(rank: 1, outlook: Fixtures.lisbonOutlooks[0], score: 71),
        RankedActivity(rank: 2, outlook: Fixtures.lisbonOutlooks[1], score: 70),
        RankedActivity(rank: 3, outlook: Fixtures.lisbonOutlooks[2], score: 48),
        RankedActivity(rank: 4, outlook: Fixtures.lisbonOutlooks[3], score: nil),
    ]

    private let formats = LabelledFormatFactory()
    private let reasons = LabelledOutlookReasons()
    private let captions = LabelledDayCaptions()
    private let banners = LabelledFreshnessBanners()
    private let now = Fixtures.referenceNow

    @Test("Items carry each ranked activity's rank, title, symbol, score and daily scores")
    func items() throws {
        let presentation = present()
        let topPick = try #require(presentation.topPick)
        let items = [topPick] + presentation.others
        #expect(items.map(\.activity) == [.surfing, .outdoorSightseeing, .indoorSightseeing, .skiing])
        #expect(items.map(\.rank) == [1, 2, 3, 4])
        #expect(items.map(\.title) == items.map { String(localized: $0.activity.title) })
        #expect(items.map(\.systemImage) == items.map(\.activity.systemImage))
        #expect(items.map(\.score) == [71, 70, 48, nil])
        #expect(items.map(\.dailyScores) == Self.ranking.map(\.outlook.dailyScores))
    }

    @Test("In week mode every item is explained by the outlook reasons over the whole forecast")
    func weekReasons() {
        let forecast = Fixtures.lisbonForecast()
        let presentation = present(forecast: forecast)
        #expect(presentation.selectedDay == nil)
        #expect(presentation.header == String(localized: .rankingHeaderWeek))
        #expect(presentation.topPick?.reason == "reason surfing over 7 days")
        #expect(presentation.others.map(\.reason) == [
            "reason outdoorSightseeing over 7 days",
            "reason indoorSightseeing over 7 days",
            "reason skiing over 7 days",
        ])
        #expect(reasons.calls.map(\.outlook) == Self.ranking.map(\.outlook))
        #expect(reasons.calls.allSatisfy { $0.days == forecast.days && formats.handedOut($0.format) })
        #expect(captions.calls.isEmpty)
    }

    @Test("In day mode every item is captioned with that day's weather and its own assessment")
    func dayCaptions() {
        let forecast = Fixtures.lisbonForecast()
        let presentation = present(day: 5, forecast: forecast)
        #expect(presentation.selectedDay == 5)
        #expect(presentation.header == String(localized: .rankingHeaderDay("date 20")))
        #expect(presentation.topPick?.reason == "caption surfing high 19 scored 28")
        #expect(presentation.others.map(\.reason) == [
            "caption outdoorSightseeing high 19 scored 40",
            "caption indoorSightseeing high 19 scored 76",
            "caption skiing high 19 blocked snowfall",
        ])
        #expect(captions.calls.map(\.activity) == Self.ranking.map(\.activity))
        #expect(captions.calls.map(\.assessment) == Self.ranking.map { $0.outlook.days.element(at: 5) })
        #expect(captions.calls.allSatisfy { $0.weather == forecast.days[5] && formats.handedOut($0.format) })
        #expect(reasons.calls.isEmpty)
    }

    @Test("A selected day beyond an outlook is captioned without an assessment")
    func dayBeyondOutlook() {
        let short = RankedActivity(rank: 1, outlook: Fixtures.outlook(.surfing, scores: [70, 90, 60]), score: 73)
        let presentation = present(day: 5, ranking: [short])
        #expect(presentation.topPick?.reason == "caption surfing high 19 unassessed")
        #expect(captions.calls.map(\.assessment) == [nil])
    }

    @Test("Selecting today's column says best today")
    func todayHeader() {
        let presentation = present(day: 0)
        #expect(presentation.selectedDay == 0)
        #expect(presentation.header == String(localized: .rankingHeaderToday))
    }

    @Test("A selected day outside the forecast falls back to the week")
    func outOfRangeDay() {
        let presentation = present(day: 7)
        #expect(presentation.selectedDay == nil)
        #expect(presentation.header == String(localized: .rankingHeaderWeek))
        #expect(presentation.topPick?.reason == "reason surfing over 7 days")
        #expect(presentation.bestDay != nil)
        #expect(captions.calls.isEmpty)
    }

    @Test(
        "The eyebrow says top pick only for a strong top pick that has a score",
        arguments: [(true, 71, true), (false, 71, false), (true, nil, false)] as [(Bool, Int?, Bool)]
    )
    func eyebrow(strong: Bool, score: Int?, isTopPick: Bool) {
        let top = RankedActivity(rank: 1, outlook: Fixtures.lisbonOutlooks[0], score: score)
        let expected = String(localized: isTopPick ? .rankingEyebrowTopPick : .rankingEyebrowBestAvailable)
        #expect(present(ranking: [top], strong: strong).eyebrow == expected)
    }

    @Test("An empty ranking has no items, no best day and the best available label")
    func emptyRanking() {
        let presentation = present(ranking: [])
        #expect(presentation.topPick == nil)
        #expect(presentation.others.isEmpty)
        #expect(presentation.bestDay == nil)
        #expect(presentation.eyebrow == String(localized: .rankingEyebrowBestAvailable))
    }

    @Test("In week mode the top pick's best day is shown with its score")
    func bestDay() {
        #expect(present().bestDay == String(localized: .rankingTopPickBestDay("day 17", 92)))
    }

    @Test("In day mode no best day is shown")
    func noBestDayInDayMode() {
        #expect(present(day: 1).bestDay == nil)
    }

    @Test("An unsuitable top pick has no best day")
    func unsuitableTopPick() {
        let skiing = RankedActivity(rank: 1, outlook: Fixtures.lisbonOutlooks[3], score: nil)
        #expect(present(ranking: [skiing]).bestDay == nil)
    }

    @Test("A best day beyond the forecast is not shown")
    func bestDayBeyondForecast() {
        let lisbon = Fixtures.lisbonForecast()
        let forecast = CityForecast(city: lisbon.city, days: Array(lisbon.days.prefix(2)), outlooks: lisbon.outlooks, fetchedAt: lisbon.fetchedAt)
        #expect(present(forecast: forecast).bestDay == nil)
    }

    @Test("Strip days carry the formatted day, the condition symbol and the temperatures")
    func stripDays() {
        let forecast = Fixtures.lisbonForecast()
        let presentation = present(forecast: forecast)
        let days = presentation.stripDays
        #expect(days.map(\.id) == Array(0...6))
        #expect(days.map(\.label) == ["today", "short 16", "short 17", "short 18", "short 19", "short 20", "short 21"])
        #expect(days.map(\.symbolName) == forecast.days.map(\.condition.systemImage))
        #expect(days.map(\.high) == ["23°", "24°", "24°", "23°", "22°", "19°", "20°"])
        #expect(days.map(\.low) == ["16°", "16°", "17°", "17°", "16°", "15°", "15°"])
        #expect(presentation.dayInitials == ["i15", "i16", "i17", "i18", "i19", "i20", "i21"])
    }

    @Test("A strip day is spoken with its condition and temperatures, adding the rain chance when labelled")
    func stripDayAccessibility() throws {
        let days = present().stripDays
        let dry = try #require(days.element(at: 0))
        let rainy = try #require(days.element(at: 5))
        let spokenRainy = String(localized: .rankingDayAccessibility("spoken 20", String(localized: WeatherCondition.rain.title), "19°", "15°"))
        #expect(dry.accessibilityLabel == String(localized: .rankingDayAccessibility(
            "spoken 15", String(localized: WeatherCondition.partlyCloudy.title), "23°", "16°"
        )))
        #expect(rainy.accessibilityLabel == String(localized: .rankingDayAccessibilityRain(spokenRainy, "80%")))
    }

    @Test(
        "Rain chance is labelled only from the threshold up",
        arguments: [
            (0.3, [nil, nil, nil, nil, nil, "80%", "50%"]),
            (0.2, [nil, nil, nil, nil, "20%", "80%", "50%"]),
        ] as [(Double, [String?])]
    )
    func precipitationThreshold(threshold: Double, labels: [String?]) {
        #expect(present(threshold: threshold).stripDays.map(\.precipitation) == labels)
    }

    @Test("A day without a rain chance has no rain label, even at a zero threshold")
    func missingRainChance() {
        let forecast = CityForecast(
            city: PreviewCities.lisbon,
            days: Fixtures.days([(.cloudy, 12, 6, nil, 10, 20, 0)]),
            outlooks: [],
            fetchedAt: now
        )
        let day = present(forecast: forecast, threshold: 0).stripDays.first
        #expect(day?.precipitation == nil)
        #expect(day?.accessibilityLabel == String(localized: .rankingDayAccessibility(
            "spoken 15", String(localized: WeatherCondition.cloudy.title), "12°", "6°"
        )))
    }

    @Test("The banner is the freshness describer's banner for the freshness, format and time")
    func banner() {
        let since = now.addingTimeInterval(-4 * 3600)
        let presentation = present(freshness: .stale(since: since))
        #expect(presentation.banner == BannerContent(kind: .stale, message: "stale since \(Int(since.timeIntervalSince1970))"))
        #expect(banners.calls.map(\.freshness) == [.stale(since: since)])
        #expect(banners.calls.map(\.now) == [now])
        #expect(banners.calls.allSatisfy { formats.handedOut($0.format) })
    }

    @Test("Updated is the formatted fetch timestamp")
    func updated() {
        let fetchedAt = now.addingTimeInterval(-600)
        #expect(present(forecast: Fixtures.lisbonForecast(fetchedAt: fetchedAt)).updated == "stamp \(Int(fetchedAt.timeIntervalSince1970)) at \(Int(now.timeIntervalSince1970))")
    }

    @Test("Title, subtitle and strip title follow the city and the forecast's day count")
    func dayCountFromForecast() {
        let lisbon = Fixtures.lisbonForecast()
        let forecast = CityForecast(city: lisbon.city, days: Array(lisbon.days.prefix(5)), outlooks: lisbon.outlooks, fetchedAt: lisbon.fetchedAt)
        let presentation = present(forecast: forecast)
        #expect(presentation.title == "Lisbon")
        #expect(presentation.subtitle == String(localized: .rankingSubtitle("Portugal", days: 5)))
        #expect(presentation.stripTitle == String(localized: .rankingStripTitle(5)))
        #expect(presentation.stripDays.count == 5)
        #expect(presentation.dayInitials.count == 5)
    }

    @Test("The forecast is formatted for its city")
    func formatsForCity() {
        _ = present()
        #expect(formats.requestedCities == [PreviewCities.lisbon])
    }

    private func makePresenter(threshold: Double) -> RankingPresenter {
        RankingPresenter(
            formats: formats,
            reasons: reasons,
            captions: captions,
            banners: banners,
            precipitationLabelThreshold: threshold,
            placeholderDayCount: 7
        )
    }

    private func present(
        day: Int? = nil,
        ranking: [RankedActivity] = RankingPresenterTests.ranking,
        strong: Bool = true,
        forecast: CityForecast = Fixtures.lisbonForecast(),
        freshness: Freshness = .fresh,
        threshold: Double = 0.3
    ) -> RankingPresentation {
        makePresenter(threshold: threshold).presentation(
            of: RankingSummary(ranking: ranking, selectedDay: day, hasStrongTopPick: strong),
            in: forecast,
            freshness: freshness,
            now: now
        )
    }
}
