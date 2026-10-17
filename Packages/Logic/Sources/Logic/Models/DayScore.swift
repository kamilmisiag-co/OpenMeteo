//
//  DayScore.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public struct DayScore: Hashable, Sendable {
    public let day: Int
    public let score: Int

    public init(day: Int, score: Int) {
        self.day = day
        self.score = score
    }
}
