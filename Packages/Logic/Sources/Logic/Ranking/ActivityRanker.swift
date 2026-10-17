//
//  ActivityRanker.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public struct ActivityRanker: ActivityRanking {
    private struct Candidate {
        let outlook: ActivityOutlook
        let score: Int?
        let bestDayScore: Int?
        let tieBreakPosition: Int
    }

    private let tieBreakOrder: [Activity]

    public init(tieBreakOrder: [Activity]) {
        self.tieBreakOrder = tieBreakOrder
    }

    public func rank(_ outlooks: [ActivityOutlook], onDay day: Int?) -> [RankedActivity] {
        outlooks
            .map { candidate(for: $0, onDay: day) }
            .sorted(by: Self.precedes)
            .enumerated()
            .map { RankedActivity(rank: $0.offset + 1, outlook: $0.element.outlook, score: $0.element.score) }
    }

    private func candidate(for outlook: ActivityOutlook, onDay day: Int?) -> Candidate {
        let score = if let day { outlook.score(onDay: day) } else { outlook.weeklyScore }
        return Candidate(
            outlook: outlook,
            score: score,
            bestDayScore: outlook.bestDay?.score,
            tieBreakPosition: tieBreakPosition(of: outlook.activity)
        )
    }

    private func tieBreakPosition(of activity: Activity) -> Int {
        tieBreakOrder.firstIndex(of: activity)
            ?? tieBreakOrder.count + (Activity.allCases.firstIndex(of: activity) ?? Activity.allCases.count)
    }

    private static func precedes(_ lhs: Candidate, _ rhs: Candidate) -> Bool {
        if let higher = higherFirst(lhs.score, rhs.score) { return higher }
        if lhs.score != nil, let higher = higherFirst(lhs.bestDayScore, rhs.bestDayScore) { return higher }
        return lhs.tieBreakPosition < rhs.tieBreakPosition
    }

    private static func higherFirst(_ lhs: Int?, _ rhs: Int?) -> Bool? {
        switch (lhs, rhs) {
        case let (left?, right?): left == right ? nil : left > right
        case (.some, nil): true
        case (nil, .some): false
        case (nil, nil): nil
        }
    }
}
