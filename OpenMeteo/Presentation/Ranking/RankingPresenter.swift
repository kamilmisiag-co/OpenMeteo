//
//  RankingPresenter.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import DesignSystem
import Foundation
import Logic
import Utils

struct RankingPresenter: RankingPresenting {
    private let formats: any ForecastFormatMaking
    private let reasons: any OutlookReasoning
    private let captions: any DayCaptioning
    private let banners: any FreshnessDescribing
    private let fallbackTimeZone: TimeZone
    private let precipitationLabelThreshold: Double
    private let placeholderDayCount: Int

    init(
        formats: any ForecastFormatMaking,
        reasons: any OutlookReasoning,
        captions: any DayCaptioning,
        banners: any FreshnessDescribing,
        fallbackTimeZone: TimeZone,
        precipitationLabelThreshold: Double,
        placeholderDayCount: Int
    ) {
        self.formats = formats
        self.reasons = reasons
        self.captions = captions
        self.banners = banners
        self.fallbackTimeZone = fallbackTimeZone
        self.precipitationLabelThreshold = precipitationLabelThreshold
        self.placeholderDayCount = placeholderDayCount
    }

    func presentation(of summary: RankingSummary, in forecast: CityForecast, freshness: Freshness, now: Date) -> RankingPresentation {
        let format = formats.format(forCityIn: forecast.city.timeZone ?? fallbackTimeZone)
        let days = forecast.days
        let selectedDay = summary.selectedDay.flatMap { days.indices.contains($0) ? $0 : nil }
        return RankingPresentation(
            title: forecast.city.name,
            subtitle: String(localized: .rankingSubtitle(forecast.city.country, days: days.count)),
            stripTitle: String(localized: .rankingStripTitle(days.count)),
            stripDays: days.enumerated().map { stripDay(at: $0.offset, on: $0.element, format: format, now: now) },
            dayInitials: days.map { format.dayInitial($0.date) },
            selectedDay: selectedDay,
            header: header(forDay: selectedDay, in: days, format: format, now: now),
            eyebrow: eyebrow(for: summary),
            topPick: summary.topPick.map { item(for: $0, onDay: selectedDay, in: days, format: format) },
            others: summary.others.map { item(for: $0, onDay: selectedDay, in: days, format: format) },
            bestDay: selectedDay == nil ? bestDay(of: summary, in: days, format: format, now: now) : nil,
            banner: banners.banner(for: freshness, format: format, now: now),
            updated: format.timestamp(forecast.fetchedAt, now: now)
        )
    }

    func placeholder(for city: City) -> RankingPresentation {
        let value = String(localized: .rankingPlaceholderValue)
        let loading = String(localized: .rankingLoading)
        let items = Activity.allCases.enumerated().map { offset, activity in
            RankingItem(
                activity: activity,
                rank: offset + 1,
                title: String(localized: activity.title),
                systemImage: activity.systemImage,
                reason: loading,
                score: nil,
                dailyScores: Array(repeating: nil, count: placeholderDayCount)
            )
        }
        return RankingPresentation(
            title: city.name,
            subtitle: String(localized: .rankingSubtitle(city.country, days: placeholderDayCount)),
            stripTitle: String(localized: .rankingStripTitle(placeholderDayCount)),
            stripDays: (0..<placeholderDayCount).map { index in
                ForecastStripDay(
                    id: index,
                    label: value,
                    symbolName: WeatherCondition.cloudy.systemImage,
                    high: value,
                    low: value,
                    precipitation: nil,
                    accessibilityLabel: loading
                )
            },
            dayInitials: Array(repeating: value, count: placeholderDayCount),
            selectedDay: nil,
            header: String(localized: .rankingHeaderWeek),
            eyebrow: String(localized: .rankingEyebrowTopPick),
            topPick: items.first,
            others: Array(items.dropFirst()),
            bestDay: nil,
            banner: nil,
            updated: value
        )
    }

    private func stripDay(at index: Int, on weather: DailyWeather, format: any ForecastFormatting, now: Date) -> ForecastStripDay {
        let high = format.temperature(weather.highCelsius)
        let low = format.temperature(weather.lowCelsius)
        let precipitation = weather.precipitationProbability.flatMap { chance in
            chance >= precipitationLabelThreshold ? format.percent(chance) : nil
        }
        let spoken = String(localized: .rankingDayAccessibility(
            format.spokenDay(weather.date),
            String(localized: weather.condition.title),
            high,
            low
        ))
        return ForecastStripDay(
            id: index,
            label: format.shortDay(weather.date, now: now),
            symbolName: weather.condition.systemImage,
            high: high,
            low: low,
            precipitation: precipitation,
            accessibilityLabel: precipitation.map { String(localized: .rankingDayAccessibilityRain(spoken, $0)) } ?? spoken
        )
    }

    private func header(forDay day: Int?, in days: [DailyWeather], format: any ForecastFormatting, now: Date) -> String {
        guard let date = day.flatMap({ days.element(at: $0) })?.date else {
            return String(localized: .rankingHeaderWeek)
        }
        guard !format.isToday(date, now: now) else {
            return String(localized: .rankingHeaderToday)
        }
        return String(localized: .rankingHeaderDay(format.dayWithDate(date)))
    }

    private func eyebrow(for summary: RankingSummary) -> String {
        let isTopPick = summary.hasStrongTopPick && summary.topPick?.score != nil
        return String(localized: isTopPick ? .rankingEyebrowTopPick : .rankingEyebrowBestAvailable)
    }

    private func item(for ranked: RankedActivity, onDay day: Int?, in days: [DailyWeather], format: any ForecastFormatting) -> RankingItem {
        RankingItem(
            activity: ranked.activity,
            rank: ranked.rank,
            title: String(localized: ranked.activity.title),
            systemImage: ranked.activity.systemImage,
            reason: reason(for: ranked.outlook, onDay: day, in: days, format: format),
            score: ranked.score,
            dailyScores: ranked.outlook.dailyScores
        )
    }

    private func reason(for outlook: ActivityOutlook, onDay day: Int?, in days: [DailyWeather], format: any ForecastFormatting) -> String {
        guard let day, let weather = days.element(at: day) else {
            return reasons.reason(for: outlook, days: days, format: format)
        }
        return captions.caption(for: outlook.activity, weather: weather, assessment: outlook.days.element(at: day), format: format)
    }

    private func bestDay(of summary: RankingSummary, in days: [DailyWeather], format: any ForecastFormatting, now: Date) -> String? {
        guard let best = summary.topPickBestDayOfWeek, let weather = days.element(at: best.day) else { return nil }
        return String(localized: .rankingTopPickBestDay(format.day(weather.date, now: now), best.score))
    }
}
