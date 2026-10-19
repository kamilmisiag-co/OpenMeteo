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
    var path: [AppRoute] = []
    var searchLatency = Duration.milliseconds(400)
    var searchLatencies: [String: Duration] = [:]
    var searchFailure: URLError?
    var forecastMode = SampleForecastProvider.Mode.live
    var forecastLatency = Duration.zero
    var locale = Locale(identifier: "en_GB")
    var timeZone = TimeZone(identifier: "Europe/Lisbon")!
    var now = PreviewForecasts.referenceNow

    func makeSession() -> AppSession {
        let session = SessionAssembler().makeSession(services: makeServices(), locale: locale, deviceTimeZone: timeZone)
        session.search.query = query
        session.search.queryDidChange()
        session.navigator.path = path
        return session
    }

    func makeRankingViewModel(for city: City) -> RankingViewModel {
        SessionAssembler()
            .makeRankingViewModels(services: makeServices(), locale: locale, deviceTimeZone: timeZone)
            .makeRankingViewModel(for: city)
    }

    private func makeServices() -> AppServices {
        let sleeper = TaskSleeper()
        let dates = PreviewDateProvider(date: now)
        let normalizer = CitySearchQueryNormalizer(
            minimumLength: StandardRules.minimumQueryLength,
            separators: StandardRules.querySeparators,
            invisibleScalars: StandardRules.queryInvisibleScalars
        )
        return AppServices(
            forecasts: SampleForecastProvider(
                mode: forecastMode,
                latency: forecastLatency,
                fallbackTimeZone: timeZone,
                dates: dates,
                sleeper: sleeper
            ),
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
            dates: dates,
            sleeper: sleeper,
            fallbackTimeZone: timeZone,
            dayCount: StandardRules.forecastDayCount
        )
    }
}
#endif
