//
//  ForecastFormatting.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation

protocol ForecastFormatting {
    func temperature(_ celsius: Double) -> String
    func speed(_ kmh: Double) -> String
    func snowfall(_ centimetres: Double) -> String
    func percent(_ fraction: Double?) -> String
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
