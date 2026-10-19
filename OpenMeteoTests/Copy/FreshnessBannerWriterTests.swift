//
//  FreshnessBannerWriterTests.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import DesignSystem
import Foundation
import Logic
import Testing
@testable import OpenMeteo

@Suite("Freshness banners")
@MainActor
struct FreshnessBannerWriterTests {
    private let writer = FreshnessBannerWriter()
    private let format = LabelledForecastFormat(timeZone: Fixtures.lisbonTimeZone)
    private let since = Date(timeIntervalSince1970: 1_000)
    private let now = Date(timeIntervalSince1970: 2_000)

    @Test("A fresh forecast has no banner")
    func fresh() {
        #expect(writer.banner(for: .fresh, format: format, now: now) == nil)
    }

    @Test("A stale forecast shows when it was fetched relative to now")
    func stale() {
        let banner = writer.banner(for: .stale(since: since), format: format, now: now)
        #expect(banner == BannerContent(kind: .stale, message: String(localized: .bannerStale("stamp 1000 at 2000"))))
    }

    @Test("An offline forecast always shows the day and time it was fetched")
    func offline() {
        let banner = writer.banner(for: .offline(since: since), format: format, now: now)
        #expect(banner == BannerContent(kind: .offline, message: String(localized: .bannerOffline("day and time 1000"))))
    }
}
