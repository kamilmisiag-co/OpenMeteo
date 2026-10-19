//
//  DayAssessment.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Utils

public struct DayAssessment: Hashable, Sendable {
    public let score: Int?
    public let blocker: Factor.Kind?
    public let effects: [Factor.Kind: Factor.Effect]

    public init(score: Int, effects: [Factor.Kind: Factor.Effect]) {
        self.score = score.clamped(to: 0...100)
        blocker = nil
        self.effects = effects
    }

    public init(blockedBy kind: Factor.Kind, effects: [Factor.Kind: Factor.Effect]) {
        var effects = effects
        effects[kind] = .hurts
        score = nil
        blocker = kind
        self.effects = effects
    }

    public var isSuitable: Bool { score != nil }
}
