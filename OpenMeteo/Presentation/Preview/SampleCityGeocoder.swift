//
//  SampleCityGeocoder.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

#if DEBUG
import Foundation
import Logic
import Utils

nonisolated struct SampleCityGeocoder: CityGeocoding {
    private let cities: [City]
    private let latency: Duration
    private let latencies: [String: Duration]
    private let failure: URLError?
    private let sleeper: any Sleeping

    init(
        cities: [City] = PreviewCities.all,
        latency: Duration = .zero,
        latencies: [String: Duration] = [:],
        failure: URLError? = nil,
        sleeper: any Sleeping
    ) {
        self.cities = cities
        self.latency = latency
        self.latencies = latencies
        self.failure = failure
        self.sleeper = sleeper
    }

    func cities(named name: String) async throws -> [City] {
        let latency = latencies[name] ?? latency
        if latency > .zero {
            try await sleeper.sleep(for: latency)
        }
        if let failure {
            throw failure
        }
        return cities.filter { $0.name.hasPrefixIgnoringCaseAndDiacritics(name) }
    }
}
#endif
