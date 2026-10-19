//
//  Calendar+Date.swift
//  UtilsMocks
//
//  Created by Kamil Misiag on 19/10/2026.
//

import Foundation

extension Calendar {
    public func date(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}
