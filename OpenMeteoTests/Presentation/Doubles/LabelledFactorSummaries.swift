//
//  LabelledFactorSummaries.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic
@testable import OpenMeteo

@MainActor
final class LabelledFactorSummaries: FactorSummarizing {
    struct SummaryCall {
        let factor: Factor
        let outlook: ActivityOutlook
        let days: [DailyWeather]
        let format: any ForecastFormatting
    }

    struct ValueCall {
        let kind: Factor.Kind
        let days: [DailyWeather]
        let format: any ForecastFormatting
    }

    private(set) var summaryCalls: [SummaryCall] = []
    private(set) var valueCalls: [ValueCall] = []

    func summary(of factor: Factor, in outlook: ActivityOutlook, days: [DailyWeather], format: any ForecastFormatting) -> String {
        summaryCalls.append(SummaryCall(factor: factor, outlook: outlook, days: days, format: format))
        return "summary \(factor.kind.rawValue) on \(factor.days.count) days"
    }

    func value(of kind: Factor.Kind, across days: [DailyWeather], format: any ForecastFormatting) -> String? {
        valueCalls.append(ValueCall(kind: kind, days: days, format: format))
        return "value \(kind.rawValue) over \(days.count) days"
    }
}
