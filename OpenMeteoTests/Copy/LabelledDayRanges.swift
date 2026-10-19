//
//  LabelledDayRanges.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic
@testable import OpenMeteo

@MainActor
final class LabelledDayRanges: DayRangeDescribing {
    struct Request: Hashable, Sendable {
        let indices: [Int]
        let days: [DailyWeather]
    }

    private let unphrased: Set<[Int]>
    private(set) var requests: [Request] = []

    init(unphrased: Set<[Int]> = []) {
        self.unphrased = unphrased
    }

    var requestedIndices: [[Int]] {
        requests.map(\.indices)
    }

    static func label(_ indices: [Int], format: any ForecastFormatting) -> String {
        "days \(format.list(indices.map(String.init)))"
    }

    func phrase(forDays indices: [Int], in days: [DailyWeather], format: any ForecastFormatting) -> String? {
        requests.append(Request(indices: indices, days: days))
        guard !indices.isEmpty, !unphrased.contains(indices) else { return nil }
        return Self.label(indices, format: format)
    }
}
