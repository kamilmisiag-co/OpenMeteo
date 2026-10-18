//
//  ActivityInsight.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public struct ActivityInsight: Hashable, Sendable {
    public let outlook: ActivityOutlook
    public let rank: Int
    public let rankedCount: Int
    public let dominantBlocker: Factor.Kind?

    public init(outlook: ActivityOutlook, rank: Int, rankedCount: Int, dominantBlocker: Factor.Kind?) {
        self.outlook = outlook
        self.rank = rank
        self.rankedCount = rankedCount
        self.dominantBlocker = dominantBlocker
    }

    public var activity: Activity { outlook.activity }
    public var weeklyScore: Int? { outlook.weeklyScore }
    public var bestDay: DayScore? { outlook.bestDay }
}
