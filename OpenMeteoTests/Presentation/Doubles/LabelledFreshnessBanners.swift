//
//  LabelledFreshnessBanners.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import DesignSystem
import Foundation
import Logic
@testable import OpenMeteo

@MainActor
final class LabelledFreshnessBanners: FreshnessDescribing {
    struct Call {
        let freshness: Freshness
        let format: any ForecastFormatting
        let now: Date
    }

    private(set) var calls: [Call] = []

    static func labelledBanner(for freshness: Freshness) -> BannerContent? {
        switch freshness {
        case .fresh: nil
        case .stale(let since): BannerContent(kind: .stale, message: "stale since \(Int(since.timeIntervalSince1970))")
        case .offline(let since): BannerContent(kind: .offline, message: "offline since \(Int(since.timeIntervalSince1970))")
        }
    }

    func banner(for freshness: Freshness, format: any ForecastFormatting, now: Date) -> BannerContent? {
        calls.append(Call(freshness: freshness, format: format, now: now))
        return Self.labelledBanner(for: freshness)
    }
}
