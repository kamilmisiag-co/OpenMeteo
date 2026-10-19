//
//  ActivityDetail.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

struct ActivityDetail: Hashable {
    let subtitle: String
    let score: Int?
    let rank: String
    let reason: String
    let bestDay: String?
    let bars: [ActivityDetailBar]
    let emptyChart: ActivityDetailEmptyChart?
    let days: [ActivityDetailDay]
    let factors: [ActivityDetailFactor]
    let scoringNote: String
    let banner: BannerContent?
}
