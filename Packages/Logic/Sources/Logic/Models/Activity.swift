//
//  Activity.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public enum Activity: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case skiing
    case surfing
    case outdoorSightseeing
    case indoorSightseeing

    public var id: String { rawValue }
}
