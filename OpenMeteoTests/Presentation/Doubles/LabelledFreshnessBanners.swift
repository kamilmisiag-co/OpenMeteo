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

    func banner(for freshness: Freshness, format: any ForecastFormatting, now: Date) -> BannerContent? {
        calls.append(Call(freshness: freshness, format: format, now: now))
        switch freshness {
        case .fresh: return nil
        case .stale(let since): return BannerContent(kind: .stale, message: "stale since \(Int(since.timeIntervalSince1970))")
        case .offline(let since): return BannerContent(kind: .offline, message: "offline since \(Int(since.timeIntervalSince1970))")
        }
    }
}
