//
//  ActivityOutlookBuilder.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Utils

public protocol OutlookBuilding: Sendable {
    func outlooks(for days: [DailyWeather]) -> [ActivityOutlook]
}

public struct ActivityOutlookBuilder: OutlookBuilding {
    private let scorers: [any ActivityScoring]

    public init(scorers: [any ActivityScoring]) {
        self.scorers = scorers.uniqued { $0.activity }
    }

    public func outlooks(for days: [DailyWeather]) -> [ActivityOutlook] {
        scorers.map { scorer in
            let assessments = Array(scorer.assess(days).prefix(days.count))
            return ActivityOutlook(activity: scorer.activity, days: assessments, factors: factors(in: assessments))
        }
    }

    private func factors(in assessments: [DayAssessment]) -> [Factor] {
        Factor.Kind.allCases
            .compactMap { factor(of: $0, in: assessments) }
            .sorted(by: precedes)
    }

    private func factor(of kind: Factor.Kind, in assessments: [DayAssessment]) -> Factor? {
        for effect in [Factor.Effect.hurts, .helps] {
            let days = assessments.indices.filter { assessments[$0].effects[kind] == effect }
            if !days.isEmpty {
                return Factor(kind: kind, effect: effect, days: days)
            }
        }
        return nil
    }

    private func precedes(_ lhs: Factor, _ rhs: Factor) -> Bool {
        if lhs.effect != rhs.effect { return lhs.effect == .hurts }
        if lhs.days.count != rhs.days.count { return lhs.days.count > rhs.days.count }
        return lhs.kind.caseIndex < rhs.kind.caseIndex
    }
}
