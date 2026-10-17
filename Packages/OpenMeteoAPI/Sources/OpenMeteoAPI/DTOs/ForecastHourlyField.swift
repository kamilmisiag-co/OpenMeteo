//
//  ForecastHourlyField.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

public enum ForecastHourlyField: String, CodingKey, CaseIterable, Sendable {
    case time
    case snowDepth = "snow_depth"

    public var isRequested: Bool {
        self != .time
    }
}
