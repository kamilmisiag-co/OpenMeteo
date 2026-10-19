//
//  RecordingRankingPresenter.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import DesignSystem
import Foundation
import Logic
@testable import OpenMeteo

@MainActor
final class RecordingRankingPresenter: RankingPresenting {
    struct Request: Hashable {
        let summary: RankingSummary
        let forecast: CityForecast
        let freshness: Freshness
        let now: Date
    }

    private(set) var requests: [Request] = []
    private(set) var placeholderCities: [City] = []

    func presentation(of summary: RankingSummary, in forecast: CityForecast, freshness: Freshness, now: Date) -> RankingPresentation {
        let request = Request(summary: summary, forecast: forecast, freshness: freshness, now: now)
        requests.append(request)
        return Self.labelledPresentation(for: request)
    }

    func placeholder(for city: City) -> RankingPresentation {
        placeholderCities.append(city)
        return Self.labelledPlaceholder(for: city)
    }

    static func labelledPresentation(for request: Request) -> RankingPresentation {
        RankingPresentation(
            title: request.forecast.city.name,
            subtitle: "fetched \(seconds(request.forecast.fetchedAt))",
            stripTitle: "\(request.forecast.days.count) days",
            stripDays: [],
            dayInitials: [],
            selectedDay: request.summary.selectedDay,
            header: request.summary.hasStrongTopPick ? "strong" : "weak",
            eyebrow: "",
            topPick: request.summary.topPick.map(item),
            others: request.summary.others.map(item),
            bestDay: nil,
            banner: labelledBanner(for: request.freshness),
            updated: "now \(seconds(request.now))"
        )
    }

    static func labelledPlaceholder(for city: City) -> RankingPresentation {
        RankingPresentation(
            title: city.name,
            subtitle: "placeholder",
            stripTitle: "",
            stripDays: [],
            dayInitials: [],
            selectedDay: nil,
            header: "",
            eyebrow: "",
            topPick: nil,
            others: [],
            bestDay: nil,
            banner: nil,
            updated: ""
        )
    }

    static func labelledBanner(for freshness: Freshness) -> BannerContent? {
        switch freshness {
        case .fresh: nil
        case .stale(let since): BannerContent(kind: .stale, message: "stale since \(seconds(since))")
        case .offline(let since): BannerContent(kind: .offline, message: "offline since \(seconds(since))")
        }
    }

    static func seconds(_ date: Date) -> Int {
        Int(date.timeIntervalSince1970)
    }

    private static func item(_ ranked: RankedActivity) -> RankingItem {
        RankingItem(
            activity: ranked.activity,
            rank: ranked.rank,
            title: ranked.activity.rawValue,
            systemImage: "",
            reason: "",
            score: ranked.score,
            dailyScores: ranked.outlook.dailyScores
        )
    }
}
