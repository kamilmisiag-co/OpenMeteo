//
//  Freshness.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation

public enum Freshness: Hashable, Sendable {
    case fresh
    case stale(since: Date)
    case offline(since: Date)
}
