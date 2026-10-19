//
//  ForecastFormat.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Utils

protocol ForecastFormatting {
    var noValue: String { get }
    func temperature(_ celsius: Double) -> String
    func temperatureRange(_ lowCelsius: Double, _ highCelsius: Double) -> String
    func speed(_ kmh: Double) -> String
    func speedRange(_ lowKmh: Double, _ highKmh: Double) -> String
    func snowfall(_ centimetres: Double) -> String
    func percent(_ fraction: Double?) -> String
    func percentRange(_ lowFraction: Double, _ highFraction: Double) -> String
    func isToday(_ date: Date, now: Date) -> Bool
    func shortDay(_ date: Date, now: Date) -> String
    func day(_ date: Date, now: Date) -> String
    func dayWithDate(_ date: Date) -> String
    func spokenDay(_ date: Date) -> String
    func dayInitial(_ date: Date) -> String
    func weekday(_ date: Date) -> String
    func time(_ date: Date) -> String
    func dayAndTime(_ date: Date) -> String
    func timestamp(_ date: Date, now: Date) -> String
    func list(_ items: [String]) -> String
}

struct ForecastFormat: ForecastFormatting {
    private let locale: Locale
    private let cityCalendar: Calendar
    private let deviceCalendar: Calendar
    private let cityDayStyle: Date.FormatStyle
    private let deviceStyle: Date.FormatStyle
    private let temperatureUnit: UnitTemperature
    private let speedUnit: UnitSpeed
    private let snowfallUnit: UnitLength

    init(locale: Locale, cityTimeZone: TimeZone, deviceTimeZone: TimeZone) {
        let cityCalendar = Calendar.gregorian(timeZone: cityTimeZone, locale: locale)
        let deviceCalendar = Calendar.gregorian(timeZone: deviceTimeZone, locale: locale)
        self.locale = locale
        temperatureUnit = UnitTemperature(forLocale: locale, usage: .weather)
        speedUnit = UnitSpeed(forLocale: locale, usage: .wind)
        snowfallUnit = UnitLength(forLocale: locale, usage: .snowfall)
        self.cityCalendar = cityCalendar
        self.deviceCalendar = deviceCalendar
        cityDayStyle = Date.FormatStyle(locale: locale, calendar: cityCalendar, timeZone: cityTimeZone)
        deviceStyle = Date.FormatStyle(locale: locale, calendar: deviceCalendar, timeZone: deviceTimeZone)
    }

    var noValue: String {
        String(localized: .formatNoValue)
    }

    func temperature(_ celsius: Double) -> String {
        guard let degrees = degrees(celsius) else { return noValue }
        return String(localized: .formatDegrees(degrees))
    }

    func temperatureRange(_ lowCelsius: Double, _ highCelsius: Double) -> String {
        guard let low = degrees(lowCelsius), let high = degrees(highCelsius) else { return noValue }
        let upper = String(localized: .formatDegrees(high))
        return low == high ? upper : range(number(low), upper)
    }

    func speed(_ kmh: Double) -> String {
        guard let value = speedValue(kmh) else { return noValue }
        return measurement(Double(value), unit: speedUnit, maximumFractionDigits: 0)
    }

    func speedRange(_ lowKmh: Double, _ highKmh: Double) -> String {
        guard let low = speedValue(lowKmh), let high = speedValue(highKmh) else { return noValue }
        let upper = measurement(Double(high), unit: speedUnit, maximumFractionDigits: 0)
        return low == high ? upper : range(number(low), upper)
    }

    func snowfall(_ centimetres: Double) -> String {
        let value = converted(centimetres, from: UnitLength.centimeters, to: snowfallUnit)
        guard value.isFinite else { return noValue }
        return measurement(max(value, 0), unit: snowfallUnit, maximumFractionDigits: 1)
    }

    func percent(_ fraction: Double?) -> String {
        guard let value = fraction.flatMap(percentValue) else { return noValue }
        return value.formatted(.percent.locale(locale))
    }

    func percentRange(_ lowFraction: Double, _ highFraction: Double) -> String {
        guard let low = percentValue(lowFraction), let high = percentValue(highFraction) else { return noValue }
        let upper = high.formatted(.percent.locale(locale))
        return low == high ? upper : range(number(low), upper)
    }

    func isToday(_ date: Date, now: Date) -> Bool {
        cityCalendar.isDate(date, inSameDayAs: now)
    }

    func shortDay(_ date: Date, now: Date) -> String {
        isToday(date, now: now) ? String(localized: .dayToday) : weekday(date)
    }

    func day(_ date: Date, now: Date) -> String {
        isToday(date, now: now) ? String(localized: .dayToday) : dayWithDate(date)
    }

    func dayWithDate(_ date: Date) -> String {
        date.formatted(cityDayStyle.weekday(.abbreviated).day())
    }

    func spokenDay(_ date: Date) -> String {
        date.formatted(cityDayStyle.weekday(.wide).day())
    }

    func dayInitial(_ date: Date) -> String {
        date.formatted(cityDayStyle.weekday(.narrow))
    }

    func weekday(_ date: Date) -> String {
        date.formatted(cityDayStyle.weekday(.abbreviated))
    }

    func time(_ date: Date) -> String {
        date.formatted(deviceStyle.hour().minute())
    }

    func dayAndTime(_ date: Date) -> String {
        date.formatted(deviceStyle.weekday(.abbreviated).day().hour().minute())
    }

    func timestamp(_ date: Date, now: Date) -> String {
        deviceCalendar.isDate(date, inSameDayAs: now) ? time(date) : dayAndTime(date)
    }

    func list(_ items: [String]) -> String {
        items.formatted(.list(type: .and).locale(locale))
    }

    private func degrees(_ celsius: Double) -> Int? {
        converted(celsius, from: UnitTemperature.celsius, to: temperatureUnit).roundedInt()
    }

    private func speedValue(_ kmh: Double) -> Int? {
        converted(kmh, from: UnitSpeed.kilometersPerHour, to: speedUnit).roundedInt()
    }

    private func percentValue(_ fraction: Double) -> Int? {
        (fraction * 100).roundedInt()
    }

    private func number(_ value: Int) -> String {
        value.formatted(.number.locale(locale))
    }

    private func range(_ lower: String, _ upper: String) -> String {
        String(localized: .formatRange(lower, upper))
    }

    private func converted<UnitType: Dimension>(_ value: Double, from source: UnitType, to target: UnitType) -> Double {
        Measurement(value: value, unit: source).converted(to: target).value
    }

    private func measurement<UnitType: Dimension>(_ value: Double, unit: UnitType, maximumFractionDigits: Int) -> String {
        Measurement(value: value, unit: unit).formatted(
            .measurement(
                width: .abbreviated,
                usage: .asProvided,
                numberFormatStyle: .number.precision(.fractionLength(0...maximumFractionDigits)).rounded(rule: .toNearestOrAwayFromZero)
            )
            .locale(locale)
        )
    }
}
