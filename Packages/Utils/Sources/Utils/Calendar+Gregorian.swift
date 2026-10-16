//
//  Calendar+Gregorian.swift
//  Utils
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation

extension Calendar {
    public static func gregorian(timeZone: TimeZone, locale: Locale? = nil) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        if let locale {
            calendar.locale = locale
        }
        return calendar
    }
}
