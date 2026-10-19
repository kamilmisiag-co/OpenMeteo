//
//  RankedActivity.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public struct RankedActivity: Identifiable, Hashable, Sendable {
    public let rank: Int
    public let outlook: ActivityOutlook
    public let score: Int?

    public init(rank: Int, outlook: ActivityOutlook, score: Int?) {
        self.rank = rank
        self.outlook = outlook
        self.score = score
    }

    public var id: Activity { outlook.activity }
    public var activity: Activity { outlook.activity }
    public var isSuitable: Bool { score != nil }
}
