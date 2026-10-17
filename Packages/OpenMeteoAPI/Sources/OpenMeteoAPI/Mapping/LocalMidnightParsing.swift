//
//  LocalMidnightParsing.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation

public protocol LocalMidnightParsing: Sendable {
    func localMidnight(ofDayKey dayKey: String, in timeZone: TimeZone) -> Date?
}
