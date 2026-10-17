//
//  ActivityRanking.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public protocol ActivityRanking: Sendable {
    func rank(_ outlooks: [ActivityOutlook], onDay day: Int?) -> [RankedActivity]
}
