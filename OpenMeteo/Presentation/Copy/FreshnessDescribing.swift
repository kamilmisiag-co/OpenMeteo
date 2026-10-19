//
//  FreshnessDescribing.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic

protocol FreshnessDescribing {
    func banner(for freshness: Freshness, format: any ForecastFormatting, now: Date) -> BannerContent?
}
