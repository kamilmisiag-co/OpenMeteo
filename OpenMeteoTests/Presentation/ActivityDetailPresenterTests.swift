//
//  ActivityDetailPresenterTests.swift
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

@Suite("Activity detail presenter")
@MainActor
struct ActivityDetailPresenterTests {
    private let formats = LabelledFormatFactory()
    private let reasons = LabelledOutlookReasons()
    private let factors = LabelledFactorSummaries()
    private let captions = LabelledDayCaptions()
    private let banners = LabelledFreshnessBanners()
    private let now = Fixtures.referenceNow

    @Test("The header shows the forecast's date range, the weekly score, the rank and the scoring note")
    func header() {
        let detail = present(insight(rank: 2, rankedCount: 4))
        #expect(detail.subtitle == String(localized: .detailSubtitle("Lisbon", "date 15", "date 21")))
        #expect(detail.score == 73)
        #expect(detail.rank == String(localized: .detailRank(2, 4)))
        #expect(detail.scoringNote == String(localized: Activity.surfing.scoringNote))
        #expect(detail.emptyChart == nil)
    }

    @Test("The reason comes from the outlook reasons for the outlook over the whole forecast")
    func reason() {
        let forecast = Fixtures.lisbonForecast()
        let detail = present(insight(), in: forecast)
        #expect(detail.reason == "reason surfing over 7 days")
        #expect(reasons.calls.map(\.outlook) == [Fixtures.lisbonOutlooks[0]])
        #expect(reasons.calls.allSatisfy { $0.days == forecast.days && formats.handedOut($0.format) })
    }

    @Test("The best day shows its date and score and is flagged on its bar and row")
    func bestDay() {
        let detail = present(insight())
        #expect(detail.bestDay == String(localized: .detailBestDay("date 17", 92)))
        #expect(detail.bars.filter(\.isBest).map(\.id) == [2])
        #expect(detail.days.filter(\.isBest).map(\.id) == [2])
    }

    @Test("A best day that is today reads best today")
    func bestDayToday() {
        let detail = present(insight(Fixtures.outlook(.surfing, scores: [95, 88, 92, 84, 76, 28, 66])))
        #expect(detail.bestDay == String(localized: .detailBestDayToday(95)))
        #expect(detail.days.filter(\.isBest).map(\.id) == [0])
    }

    @Test("A best day beyond the forecast is neither shown nor flagged")
    func bestDayBeyondForecast() {
        let lisbon = Fixtures.lisbonForecast()
        let forecast = CityForecast(city: lisbon.city, days: Array(lisbon.days.prefix(2)), outlooks: lisbon.outlooks, fetchedAt: lisbon.fetchedAt)
        let detail = present(insight(), in: forecast)
        #expect(detail.bestDay == nil)
        #expect(detail.bars.map(\.score) == [80, 88])
        #expect(detail.bars.allSatisfy { !$0.isBest })
        #expect(detail.days.allSatisfy { !$0.isBest })
        #expect(detail.subtitle == String(localized: .detailSubtitle("Lisbon", "date 15", "date 16")))
    }

    @Test("Bars are identified by day index, labelled by weekday and titled by date with the day's score")
    func bars() {
        let bars = present(insight()).bars
        #expect(bars.map(\.id) == Array(0...6))
        #expect(bars.map(\.label) == (15...21).map { "weekday \($0)" })
        #expect(bars.map(\.calloutTitle) == (15...21).map { "date \($0)" })
        #expect(bars.map(\.score) == [80, 88, 92, 84, 76, 28, 66])
    }

    @Test("A scored bar is spoken with its score and rating, an unscored one with its rating alone")
    func barAccessibility() throws {
        let outlook = Fixtures.outlook(.surfing, scores: [nil, 92])
        let bars = present(insight(outlook)).bars
        let unscored = try #require(bars.element(at: 0))
        let scored = try #require(bars.element(at: 1))
        let value = String(localized: .detailChartBarValue(92, String(localized: Rating(score: 92).title)))
        #expect(unscored.accessibilityLabel == String(localized: .detailChartBarAccessibility("spoken 15", String(localized: Rating(score: nil).title))))
        #expect(scored.accessibilityLabel == String(localized: .detailChartBarAccessibility("spoken 16", value)))
    }

    @Test("Day rows show the formatted day, the condition, the temperatures, the score and the caption")
    func dayRows() throws {
        let forecast = Fixtures.lisbonForecast()
        let days = present(insight(), in: forecast).days
        let rainy = try #require(days.element(at: 5))
        #expect(days.map(\.id) == Array(0...6))
        #expect(days.map(\.label) == ["today", "day 16", "day 17", "day 18", "day 19", "day 20", "day 21"])
        #expect(days.map(\.score) == [80, 88, 92, 84, 76, 28, 66])
        #expect(rainy.symbolName == WeatherCondition.rain.systemImage)
        #expect(rainy.conditionTitle == String(localized: WeatherCondition.rain.title))
        #expect(rainy.high == "19°")
        #expect(rainy.low == "15°")
        #expect(rainy.caption == "caption surfing high 19 scored 28")
    }

    @Test("Each day is captioned with its weather and the outlook's assessment for it")
    func dayCaptions() {
        let forecast = Fixtures.lisbonForecast()
        let outlook = Fixtures.lisbonOutlooks[0]
        _ = present(insight(outlook), in: forecast)
        #expect(captions.calls.map(\.activity) == Array(repeating: .surfing, count: 7))
        #expect(captions.calls.map(\.weather) == forecast.days)
        #expect(captions.calls.map(\.assessment) == outlook.days)
        #expect(captions.calls.allSatisfy { formats.handedOut($0.format) })
    }

    @Test("An outlook shorter than the forecast leaves the extra days unscored and unassessed")
    func shorterOutlook() {
        let detail = present(insight(Fixtures.outlook(.surfing, scores: [70, 90, 60]), rankedCount: 1))
        #expect(detail.bars.map(\.score) == [70, 90, 60, nil, nil, nil, nil])
        #expect(detail.days.map(\.score) == [70, 90, 60, nil, nil, nil, nil])
        #expect(detail.days.element(at: 5)?.caption == "caption surfing high 19 unassessed")
        #expect(captions.calls.map { $0.assessment == nil } == [false, false, false, true, true, true, true])
        #expect(detail.bars.filter(\.isBest).map(\.id) == [1])
        #expect(detail.emptyChart == nil)
    }

    @Test("A week without a score has no best day and an empty chart keyed by the dominant blocker")
    func blockedWeek() {
        let detail = present(insight(Fixtures.lisbonOutlooks[3], rank: 4, rankedCount: 4, blocker: .thunderstorm))
        #expect(detail.score == nil)
        #expect(detail.bestDay == nil)
        #expect(detail.emptyChart == ActivityDetailEmptyChart(
            title: String(localized: Factor.Kind.thunderstorm.emptyChartTitle),
            systemImage: Factor.Kind.thunderstorm.emptyChartSymbol
        ))
        #expect(detail.bars.allSatisfy { $0.score == nil && !$0.isBest })
        #expect(detail.days.allSatisfy { $0.score == nil && !$0.isBest })
    }

    @Test("A week without a score or a dominant blocker shows the generic empty chart")
    func unblockedEmptyWeek() {
        let detail = present(insight(Fixtures.lisbonOutlooks[3], blocker: nil))
        #expect(detail.emptyChart == ActivityDetailEmptyChart(title: String(localized: .detailChartEmptyOther), systemImage: "chart.bar.xaxis"))
    }

    @Test("A forecast without days falls back to the city name and the generic empty chart")
    func emptyForecast() {
        let forecast = CityForecast(city: PreviewCities.lisbon, days: [], outlooks: [], fetchedAt: now)
        let detail = present(insight(ActivityOutlook(activity: .surfing, days: [], factors: [])), in: forecast)
        #expect(detail.subtitle == "Lisbon")
        #expect(detail.bars.isEmpty)
        #expect(detail.days.isEmpty)
        #expect(detail.bestDay == nil)
        #expect(detail.emptyChart == ActivityDetailEmptyChart(title: String(localized: .detailChartEmptyOther), systemImage: "chart.bar.xaxis"))
    }

    @Test("Factors keep the outlook's order with their title, summary, value and effect")
    func factorRows() {
        let factorRows = present(insight()).factors
        let kinds: [Factor.Kind] = [.rain, .wind, .temperature]
        #expect(factorRows.map(\.kind) == kinds)
        #expect(factorRows.map(\.title) == kinds.map { String(localized: $0.title) })
        #expect(factorRows.map(\.summary) == ["summary rain on 2 days", "summary wind on 1 days", "summary temperature on 7 days"])
        #expect(factorRows.map(\.value) == ["value rain over 7 days", "value wind over 7 days", "value temperature over 7 days"])
        #expect(factorRows.map(\.helps) == [false, false, true])
    }

    @Test("Factor summaries and values are asked for with the outlook, the whole forecast and the city's format")
    func factorRequests() {
        let forecast = Fixtures.lisbonForecast()
        let outlook = Fixtures.lisbonOutlooks[0]
        _ = present(insight(outlook), in: forecast)
        #expect(factors.summaryCalls.map(\.factor) == outlook.factors)
        #expect(factors.summaryCalls.allSatisfy { $0.outlook == outlook && $0.days == forecast.days && formats.handedOut($0.format) })
        #expect(factors.valueCalls.map(\.kind) == outlook.factors.map(\.kind))
        #expect(factors.valueCalls.allSatisfy { $0.days == forecast.days && formats.handedOut($0.format) })
    }

    @Test("The banner is the freshness describer's banner for the freshness, format and time")
    func banner() {
        let since = now.addingTimeInterval(-15 * 3600)
        let detail = present(insight(), freshness: .offline(since: since))
        #expect(detail.banner == BannerContent(kind: .offline, message: "offline since \(Int(since.timeIntervalSince1970))"))
        #expect(banners.calls.map(\.freshness) == [.offline(since: since)])
        #expect(banners.calls.map(\.now) == [now])
        #expect(banners.calls.allSatisfy { formats.handedOut($0.format) })
    }

    @Test("The forecast is formatted for its city")
    func formatsForCity() {
        _ = present(insight())
        #expect(formats.requestedCities == [PreviewCities.lisbon])
    }

    private func insight(
        _ outlook: ActivityOutlook = Fixtures.lisbonOutlooks[0],
        rank: Int = 1,
        rankedCount: Int = 4,
        blocker: Factor.Kind? = nil
    ) -> ActivityInsight {
        ActivityInsight(outlook: outlook, rank: rank, rankedCount: rankedCount, dominantBlocker: blocker)
    }

    private func present(
        _ insight: ActivityInsight,
        in forecast: CityForecast = Fixtures.lisbonForecast(),
        freshness: Freshness = .fresh
    ) -> ActivityDetail {
        let presenter = ActivityDetailPresenter(
            formats: formats,
            reasons: reasons,
            factors: factors,
            captions: captions,
            banners: banners
        )
        return presenter.detail(for: insight, in: forecast, freshness: freshness, now: now)
    }
}
