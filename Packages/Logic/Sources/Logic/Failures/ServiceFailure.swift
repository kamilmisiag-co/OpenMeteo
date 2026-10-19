//
//  ServiceFailure.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public enum ServiceFailure: Hashable, Sendable {
    case offline
    case noUpcomingDays
    case unavailable
}
