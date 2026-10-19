//
//  FreshnessBannerWriter.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import DesignSystem
import Foundation
import Logic

protocol FreshnessDescribing {
    func banner(for freshness: Freshness, format: any ForecastFormatting, now: Date) -> BannerContent?
}

struct FreshnessBannerWriter: FreshnessDescribing {
    func banner(for freshness: Freshness, format: any ForecastFormatting, now: Date) -> BannerContent? {
        switch freshness {
        case .fresh:
            nil
        case .stale(let since):
            BannerContent(kind: .stale, message: String(localized: .bannerStale(format.timestamp(since, now: now))))
        case .offline(let since):
            BannerContent(kind: .offline, message: String(localized: .bannerOffline(format.dayAndTime(since))))
        }
    }
}
