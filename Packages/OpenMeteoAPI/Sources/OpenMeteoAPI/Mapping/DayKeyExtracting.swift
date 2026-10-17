//
//  DayKeyExtracting.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

public protocol DayKeyExtracting: Sendable {
    func dayKey(of timestamp: String) -> String
}
