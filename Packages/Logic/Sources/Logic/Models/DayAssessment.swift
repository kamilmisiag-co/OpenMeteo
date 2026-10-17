//
//  DayAssessment.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Utils

public struct DayAssessment: Hashable, Sendable {
    public static let scoreRange = 0...100

    public let score: Int?
    public let blocker: Factor.Kind?
    public let effects: [Factor.Kind: Factor.Effect]

    private init(score: Int?, blocker: Factor.Kind?, effects: [Factor.Kind: Factor.Effect]) {
        self.score = score
        self.blocker = blocker
        self.effects = effects
    }

    public static func scored(_ score: Int, effects: [Factor.Kind: Factor.Effect]) -> DayAssessment {
        DayAssessment(score: score.clamped(to: scoreRange), blocker: nil, effects: effects)
    }

    public static func blocked(by kind: Factor.Kind, effects: [Factor.Kind: Factor.Effect]) -> DayAssessment {
        var effects = effects
        effects[kind] = .hurts
        return DayAssessment(score: nil, blocker: kind, effects: effects)
    }

    public var isSuitable: Bool { score != nil }
}
