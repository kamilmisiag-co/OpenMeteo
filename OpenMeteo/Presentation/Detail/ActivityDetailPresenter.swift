//
//  ActivityDetailPresenter.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import DesignSystem
import Foundation
import Logic
import Utils

protocol ActivityDetailPresenting {
    func detail(for insight: ActivityInsight, in forecast: CityForecast, freshness: Freshness, now: Date) -> ActivityDetail
}

struct ActivityDetailPresenter: ActivityDetailPresenting {
    private static let fallbackEmptyChartSymbol = "chart.bar.xaxis"

    private let formats: any ForecastFormatMaking
    private let reasons: any OutlookReasoning
    private let factors: any FactorSummarizing
    private let captions: any DayCaptioning
    private let banners: any FreshnessDescribing

    init(
        formats: any ForecastFormatMaking,
        reasons: any OutlookReasoning,
        factors: any FactorSummarizing,
        captions: any DayCaptioning,
        banners: any FreshnessDescribing
    ) {
        self.formats = formats
        self.reasons = reasons
        self.factors = factors
        self.captions = captions
        self.banners = banners
    }

    func detail(for insight: ActivityInsight, in forecast: CityForecast, freshness: Freshness, now: Date) -> ActivityDetail {
        let format = formats.format(for: forecast.city)
        let outlook = insight.outlook
        let activity = insight.activity
        let days = forecast.days
        let best = insight.bestDay.flatMap { days.indices.contains($0.day) ? $0 : nil }
        let bars = days.enumerated().map { index, weather in
            bar(at: index, on: weather, score: outlook.score(onDay: index), isBest: best?.day == index, format: format)
        }
        return ActivityDetail(
            subtitle: subtitle(for: forecast.city, days: days, format: format),
            score: insight.weeklyScore,
            rank: String(localized: .detailRank(insight.rank, insight.rankedCount)),
            reason: reasons.reason(for: outlook, days: days, format: format),
            bestDay: best.flatMap { bestDay($0, in: days, format: format, now: now) },
            bars: bars,
            emptyChart: bars.contains { $0.score != nil } ? nil : emptyChart(for: insight.dominantBlocker),
            days: days.enumerated().map { index, weather in
                dayRow(at: index, on: weather, in: outlook, isBest: best?.day == index, format: format, now: now)
            },
            factors: outlook.factors.map { factorRow(for: $0, in: outlook, days: days, format: format) },
            scoringNote: String(localized: activity.scoringNote),
            banner: banners.banner(for: freshness, format: format, now: now)
        )
    }

    private func subtitle(for city: City, days: [DailyWeather], format: any ForecastFormatting) -> String {
        guard let first = days.first, let last = days.last else { return city.name }
        return String(localized: .detailSubtitle(city.name, format.dayWithDate(first.date), format.dayWithDate(last.date)))
    }

    private func bestDay(_ best: DayScore, in days: [DailyWeather], format: any ForecastFormatting, now: Date) -> String? {
        guard let weather = days.element(at: best.day) else { return nil }
        guard !format.isToday(weather.date, now: now) else {
            return String(localized: .detailBestDayToday(best.score))
        }
        return String(localized: .detailBestDay(format.dayWithDate(weather.date), best.score))
    }

    private func bar(at index: Int, on weather: DailyWeather, score: Int?, isBest: Bool, format: any ForecastFormatting) -> ActivityDetailBar {
        ActivityDetailBar(
            id: index,
            label: format.weekday(weather.date),
            calloutTitle: format.dayWithDate(weather.date),
            accessibilityLabel: String(localized: .detailChartBarAccessibility(format.spokenDay(weather.date), scoreDescription(score))),
            score: score,
            isBest: isBest
        )
    }

    private func scoreDescription(_ score: Int?) -> String {
        let rating = String(localized: Rating(score: score).title)
        guard let score else { return rating }
        return String(localized: .detailChartBarValue(score, rating))
    }

    private func emptyChart(for blocker: Factor.Kind?) -> ActivityDetailEmptyChart {
        guard let blocker else {
            return ActivityDetailEmptyChart(title: String(localized: .detailChartEmptyOther), systemImage: Self.fallbackEmptyChartSymbol)
        }
        return ActivityDetailEmptyChart(title: String(localized: blocker.emptyChartTitle), systemImage: blocker.emptyChartSymbol)
    }

    private func dayRow(
        at index: Int,
        on weather: DailyWeather,
        in outlook: ActivityOutlook,
        isBest: Bool,
        format: any ForecastFormatting,
        now: Date
    ) -> ActivityDetailDay {
        let column = WeatherColumn(weather: weather, format: format)
        return ActivityDetailDay(
            id: index,
            label: format.day(weather.date, now: now),
            symbolName: column.symbolName,
            conditionTitle: column.conditionTitle,
            high: column.high,
            low: column.low,
            score: outlook.score(onDay: index),
            caption: captions.caption(onDay: index, of: outlook, weather: weather, format: format),
            isBest: isBest
        )
    }

    private func factorRow(for factor: Factor, in outlook: ActivityOutlook, days: [DailyWeather], format: any ForecastFormatting) -> ActivityDetailFactor {
        ActivityDetailFactor(
            kind: factor.kind,
            title: String(localized: factor.kind.title),
            summary: factors.summary(of: factor, in: outlook, days: days, format: format),
            value: factors.value(of: factor.kind, across: days, format: format),
            helps: factor.effect == .helps
        )
    }
}
