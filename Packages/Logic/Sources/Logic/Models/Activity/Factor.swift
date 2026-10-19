//
//  Factor.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public struct Factor: Hashable, Codable, Sendable {
    public enum Kind: String, CaseIterable, Codable, Hashable, Sendable {
        case wind
        case rain
        case temperature
        case thunderstorm
        case snowfall
    }

    public enum Effect: String, CaseIterable, Codable, Hashable, Sendable {
        case helps
        case hurts
    }

    public let kind: Kind
    public let effect: Effect
    public let days: [Int]

    public init(kind: Kind, effect: Effect, days: [Int]) {
        self.kind = kind
        self.effect = effect
        self.days = days
    }
}
