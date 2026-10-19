//
//  AppComposer.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic
import Networking
import OpenMeteoAPI
import OSLog
import Storage
import Utils

struct AppComposer: AppComposing {
    private let logSubsystem: String

    init(logSubsystem: String) {
        self.logSubsystem = logSubsystem
    }

    func makeSession() -> AppSession {
        let locale = Locale.autoupdatingCurrent
        let services = services(locale: locale, fallbackTimeZone: TimeZone.current)
        return SessionAssembler().makeSession(services: services, locale: locale, deviceTimeZone: TimeZone.autoupdatingCurrent)
    }

    private func services(locale: Locale, fallbackTimeZone: TimeZone) -> AppServices {
        let dates = SystemDateProvider()
        let sleeper = TaskSleeper()
        let transport = URLSessionTransport(loader: urlSession())
        let retryPolicy = retryPolicy(dates: dates)
        let observers: [any NetworkObserver] = [
            LoggingNetworkObserver(logger: Logger(subsystem: logSubsystem, category: AppStandard.networkLogCategory)),
        ]
        let geocodingClient = client(baseURL: OpenMeteoStandard.geocodingBaseURL, transport: transport, retryPolicy: retryPolicy, sleeper: sleeper, observers: observers)
        let forecastClient = client(baseURL: OpenMeteoStandard.forecastBaseURL, transport: transport, retryPolicy: retryPolicy, sleeper: sleeper, observers: observers)
        let storageReporter = LoggerStorageFailureReporter(
            logger: Logger(subsystem: logSubsystem, category: AppStandard.storageLogCategory)
        )
        let normalizer = CitySearchQueryNormalizer(
            minimumLength: StandardRules.minimumQueryLength,
            separators: StandardRules.querySeparators,
            invisibleScalars: StandardRules.queryInvisibleScalars
        )
        return AppServices(
            forecasts: ForecastService(
                weather: forecaster(client: forecastClient, fallbackTimeZone: fallbackTimeZone),
                cache: CodableWeatherCache(
                    records: records(in: .cachesDirectory, named: StorageStandard.weatherCacheDirectoryName, reporter: storageReporter),
                    keys: PrefixedCityKey(prefix: StorageStandard.weatherKeyPrefix)
                ),
                window: UpcomingDaysWindow(dayCount: StandardRules.forecastDayCount, fallbackTimeZone: fallbackTimeZone),
                outlookBuilder: ActivityOutlookBuilder(scorers: StandardRules.scorers),
                fallbackPolicy: ConnectivityFallbackPolicy(),
                dateProvider: dates
            ),
            citySearch: CitySearchService(geocoder: geocoder(client: geocodingClient, locale: locale), normalizer: normalizer),
            queryNormalizer: normalizer,
            recents: RecentCitiesService(
                store: CodableRecentCitiesStore(
                    records: records(in: .applicationSupportDirectory, named: StorageStandard.recentCitiesDirectoryName, reporter: storageReporter),
                    key: StorageStandard.recentCitiesKey
                ),
                maximumCount: StandardRules.maximumRecentCities
            ),
            dates: dates,
            sleeper: sleeper,
            fallbackTimeZone: fallbackTimeZone,
            dayCount: StandardRules.forecastDayCount
        )
    }

    private func urlSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = OpenMeteoStandard.requestTimeout.timeInterval
        return URLSession(configuration: configuration)
    }

    private func client(
        baseURL: URL,
        transport: any HTTPTransport,
        retryPolicy: any RetryPolicy,
        sleeper: any Sleeping,
        observers: [any NetworkObserver]
    ) -> any HTTPClient {
        NetworkClient(
            requestBuilder: RequestBuilder(
                configuration: RequestConfiguration(
                    baseURL: baseURL,
                    defaultHeaders: [:],
                    timeout: OpenMeteoStandard.requestTimeout,
                    cachePolicy: .useProtocolCachePolicy
                ),
                encoder: JSONEncoder(),
                contentType: "application/json"
            ),
            interceptors: [],
            transport: transport,
            validator: StatusCodeValidator(acceptableStatusCodes: 200..<300),
            decoder: JSONDecoder(),
            retryPolicy: retryPolicy,
            sleeper: sleeper,
            observers: observers
        )
    }

    private func retryPolicy(dates: any DateProviding) -> any RetryPolicy {
        ExponentialBackoffRetryPolicy(
            maximumRetries: OpenMeteoStandard.maximumRetries,
            initialDelay: OpenMeteoStandard.initialRetryDelay,
            multiplier: OpenMeteoStandard.retryDelayMultiplier,
            maximumDelay: OpenMeteoStandard.maximumRetryDelay,
            jitter: OpenMeteoStandard.retryJitter,
            randomFraction: { Double.random(in: 0...1) },
            dateProvider: dates,
            retryableMethods: OpenMeteoStandard.retryableMethods,
            retryableStatusCodes: OpenMeteoStandard.retryableStatusCodes,
            retryableURLErrorCodes: OpenMeteoStandard.retryableURLErrorCodes
        )
    }

    private func geocoder(client: any HTTPClient, locale: Locale) -> any CityGeocoding {
        OpenMeteoGeocoder(
            client: client,
            requests: GeocodingRequestFactory(
                resultLimit: OpenMeteoStandard.geocodingResultLimit,
                languageCodes: LocaleLanguageCodeProvider(locale: locale, fallbackLanguageCode: OpenMeteoStandard.fallbackLanguageCode)
            ),
            mapper: GeocodingCityMapper(regionNames: LocaleRegionNameProvider(locale: locale))
        )
    }

    private func forecaster(client: any HTTPClient, fallbackTimeZone: TimeZone) -> any WeatherForecasting {
        OpenMeteoWeatherForecaster(
            client: client,
            requests: ForecastRequestFactory(
                dayCounts: PaddedForecastDayCount(
                    additionalDays: OpenMeteoStandard.additionalForecastDays,
                    maximumDays: OpenMeteoStandard.maximumForecastDays
                ),
                fallbackTimeZoneIdentifier: fallbackTimeZone.identifier
            ),
            mapper: ForecastDailyWeatherMapper(
                weatherCodes: WMOWeatherCodeMapper(),
                timeZones: ResponseTimeZoneResolver(fallbackTimeZone: fallbackTimeZone),
                dayKeys: GregorianDayKeyParser(),
                snowDepths: HourlySnowDepthAggregator(),
                units: OpenMeteoStandard.forecastUnits
            )
        )
    }

    private func records(in root: URL, named name: String, reporter: any StorageFailureReporting) -> any RecordStoring {
        ReportingRecordStore(
            store: FileDataStore(
                directory: root.appending(path: name, directoryHint: .isDirectory),
                fileSystem: FoundationFileSystem(),
                fileNames: SafeFileNameEncoder(fileExtension: StorageStandard.fileExtension)
            ),
            encoder: JSONEncoder(),
            decoder: JSONDecoder(),
            reporter: reporter
        )
    }
}
