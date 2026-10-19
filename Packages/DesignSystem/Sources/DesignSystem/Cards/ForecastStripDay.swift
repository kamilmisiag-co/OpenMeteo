//
//  ForecastStripDay.swift
//  DesignSystem
//
//  Created by Kamil Misiag on 19/10/2026.
//

public struct ForecastStripDay: Identifiable, Hashable, Sendable {
    public let id: Int
    public let label: String
    public let symbolName: String
    public let high: String
    public let low: String
    public let precipitation: String?
    public let accessibilityLabel: String

    public init(id: Int, label: String, symbolName: String, high: String, low: String, precipitation: String?, accessibilityLabel: String) {
        self.id = id
        self.label = label
        self.symbolName = symbolName
        self.high = high
        self.low = low
        self.precipitation = precipitation
        self.accessibilityLabel = accessibilityLabel
    }
}
