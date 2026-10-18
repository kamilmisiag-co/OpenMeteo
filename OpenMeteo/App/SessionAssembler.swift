//
//  SessionAssembler.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic

struct SessionAssembler {
    func makeSession(services: AppServices, locale: Locale, deviceTimeZone: TimeZone) -> AppSession {
        AppSession(
            search: SearchViewModel(dependencies: searchDependencies(services: services)),
            navigator: AppNavigator(rankings: makeRankingViewModels(services: services, locale: locale, deviceTimeZone: deviceTimeZone)),
            links: AttributionLinks(
                openMeteo: URL(string: AppStandard.openMeteoURLString),
                licence: URL(string: AppStandard.licenceURLString),
                geoNames: URL(string: AppStandard.geoNamesURLString)
            ),
            dayCount: services.dayCount
        )
    }

    func makeRankingViewModels(services: AppServices, locale: Locale, deviceTimeZone: TimeZone) -> any RankingViewModelMaking {
        RankingViewModelFactory(
            dependencies: rankingDependencies(
                services: services,
                formats: LocaleForecastFormatFactory(locale: locale, deviceTimeZone: deviceTimeZone)
            )
        )
    }

    private func searchDependencies(services: AppServices) -> SearchViewModel.Dependencies {
        SearchViewModel.Dependencies(
            resolver: CitySearchFlow(
                search: services.citySearch,
                normalizer: services.queryNormalizer,
                sleeper: services.sleeper,
                debounce: StandardRules.searchDebounce,
                failures: ErrorSearchFailureClassifier()
            ),
            recents: services.recents,
            sleeper: services.sleeper,
            debounce: StandardRules.searchDebounce,
            progressDelay: AppStandard.searchProgressDelay
        )
    }

    private func rankingDependencies(services: AppServices, formats: any ForecastFormatMaking) -> RankingViewModel.Dependencies {
        let dayRanges = DayRangePhraser()
        let reasons = OutlookReasonWriter(dayRanges: dayRanges, maximumCauses: AppStandard.maximumReasonCauses)
        let captions = DayCaptionWriter()
        let banners = FreshnessBannerWriter()
        let ranker = ActivityRanker(tieBreakOrder: StandardRules.tieBreakOrder)
        return RankingViewModel.Dependencies(
            loader: ForecastLoader(forecasts: services.forecasts, failures: ErrorFailureClassifier()),
            updater: ForecastStateUpdater(days: DateMatchingDaySelection()),
            daySelector: ToggleDaySelector(),
            summarizer: RankingSummarizer(ranker: ranker, strongScoreThreshold: StandardRules.strongScoreThreshold),
            insights: ActivityInsightBuilder(ranker: ranker),
            freshness: FreshnessEvaluator(staleAfter: StandardRules.staleAfter),
            dates: services.dates,
            presenter: RankingPresenter(
                formats: formats,
                reasons: reasons,
                captions: captions,
                banners: banners,
                fallbackTimeZone: services.fallbackTimeZone,
                precipitationLabelThreshold: AppStandard.precipitationLabelThreshold,
                placeholderDayCount: services.dayCount
            ),
            detailPresenter: ActivityDetailPresenter(
                formats: formats,
                reasons: reasons,
                factors: FactorSummaryWriter(dayRanges: dayRanges),
                captions: captions,
                banners: banners,
                fallbackTimeZone: services.fallbackTimeZone
            ),
            standardDayCount: services.dayCount
        )
    }
}
