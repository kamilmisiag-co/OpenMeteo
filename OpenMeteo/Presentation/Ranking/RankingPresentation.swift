//
//  RankingPresentation.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import DesignSystem

struct RankingPresentation: Hashable {
    let title: String
    let subtitle: String
    let stripTitle: String
    let stripDays: [ForecastStripDay]
    let dayInitials: [String]
    let selectedDay: Int?
    let header: String
    let eyebrow: String
    let topPick: RankingItem?
    let others: [RankingItem]
    let bestDay: String?
    let banner: BannerContent?
    let updated: String
}
