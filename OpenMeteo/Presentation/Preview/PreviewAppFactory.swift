//
//  PreviewAppFactory.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

#if DEBUG
import Foundation
import Logic
import Utils

struct PreviewAppFactory {
    var recents: [City] = []
    var query = ""
    var searchLatency = Duration.milliseconds(400)
    var searchLatencies: [String: Duration] = [:]
    var searchFailure: URLError?

    func makeSession() -> AppSession {
        let session = SessionAssembler().makeSession(services: makeServices())
        session.search.query = query
        session.search.queryDidChange()
        return session
    }

    private func makeServices() -> AppServices {
        let sleeper = TaskSleeper()
        let normalizer = CitySearchQueryNormalizer(
            minimumLength: StandardRules.minimumQueryLength,
            separators: StandardRules.querySeparators,
            invisibleScalars: StandardRules.queryInvisibleScalars
        )
        return AppServices(
            citySearch: CitySearchService(
                geocoder: SampleCityGeocoder(
                    latency: searchLatency,
                    latencies: searchLatencies,
                    failure: searchFailure,
                    sleeper: sleeper
                ),
                normalizer: normalizer
            ),
            queryNormalizer: normalizer,
            recents: RecentCitiesService(
                store: PreviewRecentCitiesStore(cities: recents),
                maximumCount: StandardRules.maximumRecentCities
            ),
            sleeper: sleeper,
            dayCount: StandardRules.forecastDayCount
        )
    }
}
#endif
