//
//  RankingItem.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic

struct RankingItem: Identifiable, Hashable {
    let activity: Activity
    let rank: Int
    let title: String
    let systemImage: String
    let reason: String
    let score: Int?
    let dailyScores: [Int?]

    var id: Activity { activity }
}
