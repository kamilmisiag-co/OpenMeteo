//
//  LabelledForecastFormat.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Utils
@testable import OpenMeteo

final class LabelledForecastFormat: ForecastFormatting {
    let timeZone: TimeZone

    init(timeZone: TimeZone) {
        self.timeZone = timeZone
    }

    func temperature(_ celsius: Double) -> String {
        "\(whole(celsius))°"
    }

    func speed(_ kmh: Double) -> String {
        "\(whole(kmh)) kmh"
    }

    func snowfall(_ centimetres: Double) -> String {
        "\(whole(centimetres)) cm"
    }

    func percent(_ fraction: Double?) -> String {
        fraction.map { "\(whole($0 * 100))%" } ?? "no chance"
    }

    func isToday(_ date: Date, now: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: now)
    }

    func shortDay(_ date: Date, now: Date) -> String {
        isToday(date, now: now) ? "today" : "short \(dayOfMonth(date))"
    }

    func day(_ date: Date, now: Date) -> String {
        isToday(date, now: now) ? "today" : "day \(dayOfMonth(date))"
    }

    func dayWithDate(_ date: Date) -> String {
        "date \(dayOfMonth(date))"
    }

    func spokenDay(_ date: Date) -> String {
        "spoken \(dayOfMonth(date))"
    }

    func dayInitial(_ date: Date) -> String {
        "i\(dayOfMonth(date))"
    }

    func weekday(_ date: Date) -> String {
        "weekday \(dayOfMonth(date))"
    }

    func time(_ date: Date) -> String {
        "time \(Int(date.timeIntervalSince1970))"
    }

    func dayAndTime(_ date: Date) -> String {
        "day and time \(Int(date.timeIntervalSince1970))"
    }

    func timestamp(_ date: Date, now: Date) -> String {
        "stamp \(Int(date.timeIntervalSince1970)) at \(Int(now.timeIntervalSince1970))"
    }

    func list(_ items: [String]) -> String {
        items.joined(separator: " + ")
    }

    private func whole(_ value: Double) -> String {
        value.roundedInt().map(String.init) ?? "not finite"
    }

    private var calendar: Calendar {
        Calendar.gregorian(timeZone: timeZone)
    }

    private func dayOfMonth(_ date: Date) -> Int {
        calendar.component(.day, from: date)
    }
}
