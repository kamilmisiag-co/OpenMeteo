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

    func makeSession() throws -> AppSession {
        SessionAssembler().makeSession(services: try services(locale: Locale.autoupdatingCurrent))
    }

    private func services(locale: Locale) throws -> AppServices {
        let dates = SystemDateProvider()
        let sleeper = TaskSleeper()
        let transport = URLSessionTransport(loader: urlSession())
        let retryPolicy = retryPolicy(dates: dates)
        let observers: [any NetworkObserver] = [
            LoggingNetworkObserver(logger: Logger(subsystem: logSubsystem, category: AppStandard.networkLogCategory)),
        ]
        let geocodingClient = try client(host: OpenMeteoStandard.geocodingHost, transport: transport, retryPolicy: retryPolicy, sleeper: sleeper, observers: observers)
        let storageReporter = LoggerStorageFailureReporter(
            logger: Logger(subsystem: logSubsystem, category: AppStandard.storageLogCategory)
        )
        let normalizer = CitySearchQueryNormalizer(
            minimumLength: StandardRules.minimumQueryLength,
            separators: StandardRules.querySeparators,
            invisibleScalars: StandardRules.queryInvisibleScalars
        )
        return AppServices(
            citySearch: CitySearchService(geocoder: geocoder(client: geocodingClient, locale: locale), normalizer: normalizer),
            queryNormalizer: normalizer,
            recents: RecentCitiesService(
                store: CodableRecentCitiesStore(
                    records: records(in: .applicationSupportDirectory, named: StorageStandard.recentCitiesDirectoryName, reporter: storageReporter),
                    key: StorageStandard.recentCitiesKey
                ),
                maximumCount: StandardRules.maximumRecentCities
            ),
            sleeper: sleeper,
            dayCount: StandardRules.forecastDayCount
        )
    }

    private func urlSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = OpenMeteoStandard.requestTimeout / .seconds(1)
        return URLSession(configuration: configuration)
    }

    private func client(
        host: String,
        transport: any HTTPTransport,
        retryPolicy: any RetryPolicy,
        sleeper: any Sleeping,
        observers: [any NetworkObserver]
    ) throws -> any HTTPClient {
        NetworkClient(
            requestBuilder: RequestBuilder(
                configuration: RequestConfiguration(
                    baseURL: try baseURL(host: host),
                    defaultHeaders: [:],
                    timeout: OpenMeteoStandard.requestTimeout,
                    cachePolicy: .useProtocolCachePolicy
                ),
                bodyEncoder: JSONBodyEncoder(encoder: JSONEncoder(), contentType: "application/json")
            ),
            interceptors: [],
            transport: transport,
            validator: StatusCodeValidator(acceptableStatusCodes: 200..<300),
            decoder: JSONResponseDecoder(decoder: JSONDecoder()),
            retryPolicy: retryPolicy,
            sleeper: sleeper,
            observers: observers
        )
    }

    private func baseURL(host: String) throws -> URL {
        var components = URLComponents()
        components.scheme = OpenMeteoStandard.scheme
        components.host = host
        guard let url = components.url else { throw AppCompositionError.invalidBaseURL(host: host) }
        return url
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
                allowedResultLimits: OpenMeteoStandard.geocodingResultLimits,
                languageCodes: LocaleLanguageCodeProvider(locale: locale, fallbackLanguageCode: OpenMeteoStandard.fallbackLanguageCode)
            ),
            mapper: GeocodingCityMapper(regionNames: LocaleRegionNameProvider(locale: locale))
        )
    }

    private func records(in root: URL, named name: String, reporter: any StorageFailureReporting) -> any RecordStoring {
        ReportingRecordStore(
            store: FileDataStore(
                directory: root.appending(path: name, directoryHint: .isDirectory),
                fileSystem: FoundationFileSystem(),
                fileNames: SafeFileNameEncoder(
                    allowedCharacters: StorageStandard.allowedKeyCharacters,
                    fileExtension: StorageStandard.fileExtension
                )
            ),
            encoder: JSONValueEncoder(encoder: JSONEncoder()),
            decoder: JSONValueDecoder(decoder: JSONDecoder()),
            reporter: reporter
        )
    }
}
