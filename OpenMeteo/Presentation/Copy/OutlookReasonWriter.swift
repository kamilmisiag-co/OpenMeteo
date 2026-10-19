//
//  OutlookReasonWriter.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import DesignSystem
import Foundation
import Logic
import Utils

protocol OutlookReasoning {
    func reason(for outlook: ActivityOutlook, days: [DailyWeather], format: any ForecastFormatting) -> String
}

struct OutlookReasonWriter: OutlookReasoning {
    private typealias Clause = (text: String, dayCount: Int)

    private let dayRanges: any DayRangeDescribing
    private let maximumCauses: Int

    init(dayRanges: any DayRangeDescribing, maximumCauses: Int) {
        self.dayRanges = dayRanges
        self.maximumCauses = max(0, maximumCauses)
    }

    func reason(for outlook: ActivityOutlook, days: [DailyWeather], format: any ForecastFormatting) -> String {
        let outlook = ActivityOutlook(activity: outlook.activity, days: Array(outlook.days.prefix(days.count)), factors: outlook.factors)
        let assessments = outlook.days
        let good = assessments.indices.filter { isGood(assessments[$0]) }
        let weak = assessments.indices.filter { assessments[$0].score != nil && !isGood(assessments[$0]) }
        let blocked = assessments.indices.filter { assessments[$0].blocker != nil }
        let blocker = outlook.dominantBlocker

        let positive = dayRanges.phrase(forDays: good, in: days, format: format).map { String(localized: .reasonGood($0)) }
        let negatives = ordered(
            blockedClause(for: blocked, blocker: blocker, days: days, format: format),
            heldBackClause(for: weak, excluding: blocker, outlook: outlook, days: days, format: format)
        )
        let clauses = positive.map { [$0] + negatives.prefix(1) } ?? Array(negatives.prefix(2))
        guard let first = clauses.first else {
            return peak(of: outlook, days: days, format: format)
                ?? String(localized: .reasonBlockedOther(String(localized: .dayAllWeek)))
        }
        return clauses.dropFirst().reduce(first) { String(localized: .reasonJoin($0, $1)) }
    }

    private func isGood(_ assessment: DayAssessment) -> Bool {
        guard assessment.score != nil else { return false }
        switch Rating(score: assessment.score) {
        case .excellent, .good: return true
        case .fair, .poor, .notSuitable: return false
        }
    }

    private func blockedClause(for blocked: [Int], blocker: Factor.Kind?, days: [DailyWeather], format: any ForecastFormatting) -> Clause? {
        guard let blocker, let phrase = dayRanges.phrase(forDays: blocked, in: days, format: format) else { return nil }
        let text = switch blocker {
        case .snowfall: String(localized: .reasonBlockedSnowfall(phrase))
        case .thunderstorm: String(localized: .reasonBlockedThunderstorm(phrase))
        case .wind, .rain, .temperature: String(localized: .reasonBlockedOther(phrase))
        }
        return (text, blocked.count)
    }

    private func heldBackClause(
        for weak: [Int],
        excluding blocker: Factor.Kind?,
        outlook: ActivityOutlook,
        days: [DailyWeather],
        format: any ForecastFormatting
    ) -> Clause? {
        let weakDays = Set(weak)
        let causes = outlook.factors
            .filter { $0.effect == .hurts && $0.kind != blocker && !weakDays.isDisjoint(with: $0.days) }
            .map(\.kind)
            .uniqued()
            .prefix(maximumCauses)
            .map { String(localized: $0.cause) }
        guard !causes.isEmpty, let phrase = dayRanges.phrase(forDays: weak, in: days, format: format) else { return nil }
        return (String(localized: .reasonHeldBack(format.list(causes), phrase)), weak.count)
    }

    private func ordered(_ blocked: Clause?, _ heldBack: Clause?) -> [String] {
        switch (blocked, heldBack) {
        case let (blocked?, heldBack?):
            heldBack.dayCount > blocked.dayCount ? [heldBack.text, blocked.text] : [blocked.text, heldBack.text]
        case let (blocked?, nil):
            [blocked.text]
        case let (nil, heldBack?):
            [heldBack.text]
        case (nil, nil):
            []
        }
    }

    private func peak(of outlook: ActivityOutlook, days: [DailyWeather], format: any ForecastFormatting) -> String? {
        guard let best = outlook.bestDay, let day = days.element(at: best.day) else { return nil }
        return String(localized: .reasonPeak(format.weekday(day.date), best.score))
    }
}
