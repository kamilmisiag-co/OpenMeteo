//
//  ForecastUnits.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

public struct ForecastUnits: Hashable, Sendable {
    public let percentPerFraction: Double
    public let centimetresPerSnowDepthUnit: Double

    public init(percentPerFraction: Double, centimetresPerSnowDepthUnit: Double) {
        self.percentPerFraction = percentPerFraction
        self.centimetresPerSnowDepthUnit = centimetresPerSnowDepthUnit
    }
}
