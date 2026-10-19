//
//  GregorianDayKeyParser.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Utils

public protocol DayKeyExtracting: Sendable {
    func dayKey(of timestamp: String) -> String
}

public protocol LocalMidnightParsing: Sendable {
    func localMidnight(ofDayKey dayKey: String, in timeZone: TimeZone) -> Date?
}

public struct GregorianDayKeyParser: DayKeyExtracting, LocalMidnightParsing {
    public init() {}

    public func dayKey(of timestamp: String) -> String {
        String(timestamp.prefix { $0 != "T" })
    }

    public func localMidnight(ofDayKey dayKey: String, in timeZone: TimeZone) -> Date? {
        let calendar = Calendar.gregorian(timeZone: timeZone)
        let parts = dayKey.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.map(\.count) == [4, 2, 2],
              parts.allSatisfy(\.isASCIIDigits),
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]),
              let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else { return nil }
        let resolved = calendar.dateComponents([.year, .month, .day], from: date)
        guard resolved.year == year, resolved.month == month, resolved.day == day else { return nil }
        return calendar.startOfDay(for: date)
    }
}
