//
//  OutlookReasonWriterTests.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic
import Testing
@testable import OpenMeteo

@Suite("Outlook reasons")
@MainActor
struct OutlookReasonWriterTests {
    private let days = Fixtures.days(Fixtures.lisbonWeather)
    private let format = LabelledForecastFormat(timeZone: Fixtures.lisbonTimeZone)

    private var allDays: [Int] {
        Array(days.indices)
    }

    private func reason(
        _ assessments: [DayAssessment],
        factors: [Factor] = [],
        maximumCauses: Int = 2,
        dayRanges: LabelledDayRanges = LabelledDayRanges(),
        days: [DailyWeather]? = nil
    ) -> String {
        let writer = OutlookReasonWriter(dayRanges: dayRanges, maximumCauses: maximumCauses)
        let outlook = ActivityOutlook(activity: .outdoorSightseeing, days: assessments, factors: factors)
        return writer.reason(for: outlook, days: days ?? self.days, format: format)
    }

    private func week(blocked: [Int] = [], by blocker: Factor.Kind = .thunderstorm, weak: [Int] = []) -> [DayAssessment] {
        allDays.map { day in
            guard !blocked.contains(day) else { return DayAssessment(blockedBy: blocker, effects: [:]) }
            return scored(weak.contains(day) ? 40 : 80)
        }
    }

    private func goodDays(blocked: [Int] = [], weak: [Int] = []) -> [Int] {
        allDays.filter { !blocked.contains($0) && !weak.contains($0) }
    }

    private func scored(_ score: Int) -> DayAssessment {
        DayAssessment(score: score, effects: [:])
    }

    private func blocked(_ kind: Factor.Kind) -> DayAssessment {
        DayAssessment(blockedBy: kind, effects: [:])
    }

    private func hurts(_ kind: Factor.Kind, on days: [Int]) -> Factor {
        Factor(kind: kind, effect: .hurts, days: days)
    }

    private func label(_ indices: [Int]) -> String {
        LabelledDayRanges.label(indices, format: format)
    }

    private func good(_ indices: [Int]) -> String {
        String(localized: .reasonGood(label(indices)))
    }

    private func heldBack(by causes: [Factor.Kind], on indices: [Int]) -> String {
        String(localized: .reasonHeldBack(format.list(causes.map { String(localized: $0.cause) }), label(indices)))
    }

    private func join(_ first: String, _ second: String) -> String {
        String(localized: .reasonJoin(first, second))
    }

    @Test("Days are split into good, blocked and weak, and each group is phrased over the forecast's days")
    func dayGroups() {
        let dayRanges = LabelledDayRanges()
        let assessments = [scored(80), scored(60), scored(59), scored(0), blocked(.wind), scored(100), scored(40)]

        let result = reason(assessments, factors: [hurts(.temperature, on: [2])], dayRanges: dayRanges)

        #expect(dayRanges.requestedIndices == [[0, 1, 5], [4], [2, 3, 6]])
        #expect(dayRanges.requests.allSatisfy { $0.days == days })
        #expect(result == join(good([0, 1, 5]), heldBack(by: [.temperature], on: [2, 3, 6])))
    }

    @Test("Next to good days, blocked days win when they cover at least as many days as the weak days", arguments: [
        ([3, 4], [5]),
        ([3], [5]),
    ])
    func blockedNextToGood(blockedDays: [Int], weakDays: [Int]) {
        let result = reason(week(blocked: blockedDays, weak: weakDays), factors: [hurts(.rain, on: allDays)])
        let expected = join(good(goodDays(blocked: blockedDays, weak: weakDays)), String(localized: .reasonBlockedThunderstorm(label(blockedDays))))
        #expect(result == expected)
    }

    @Test("Next to good days, weak days win when they cover more days than the blocked days")
    func weakNextToGood() {
        let result = reason(week(blocked: [3], weak: [4, 5]), factors: [hurts(.rain, on: allDays)])
        #expect(result == join(good(goodDays(blocked: [3], weak: [4, 5])), heldBack(by: [.rain], on: [4, 5])))
    }

    @Test("Without good days both negative clauses are joined, the larger first, and the blocker is not a cause")
    func twoNegativeClauses() {
        let result = reason(
            week(blocked: [0, 6], by: .snowfall, weak: [1, 2, 3, 4, 5]),
            factors: [hurts(.snowfall, on: allDays), hurts(.temperature, on: allDays)]
        )
        let expected = join(heldBack(by: [.temperature], on: [1, 2, 3, 4, 5]), String(localized: .reasonBlockedSnowfall(label([0, 6]))))
        #expect(result == expected)
    }

    @Test("The most frequent blocker names the clause for every blocked day and only it is left out of the causes")
    func dominantBlocker() {
        let assessments = [blocked(.thunderstorm), blocked(.thunderstorm), blocked(.wind), scored(30), scored(30), scored(30), scored(30)]
        let factors = [hurts(.wind, on: Array(2...6)), hurts(.thunderstorm, on: [0, 1, 3]), hurts(.rain, on: [3])]

        let result = reason(assessments, factors: factors)

        let expected = join(heldBack(by: [.wind, .rain], on: [3, 4, 5, 6]), String(localized: .reasonBlockedThunderstorm(label([0, 1, 2]))))
        #expect(result == expected)
    }

    @Test("Only factors that hurt on weak days count as causes, once each and in the outlook's order")
    func causesFromWeakDays() {
        let factors = [
            hurts(.wind, on: [0]),
            Factor(kind: .rain, effect: .helps, days: [5]),
            hurts(.temperature, on: [4, 5]),
            hurts(.thunderstorm, on: [5]),
            hurts(.temperature, on: [5]),
        ]

        let result = reason(week(weak: [5]), factors: factors, maximumCauses: 3)

        #expect(result == join(good(goodDays(weak: [5])), heldBack(by: [.temperature, .thunderstorm], on: [5])))
    }

    @Test("Causes are capped at the maximum")
    func causeLimit() {
        let result = reason(week(weak: [5]), factors: [hurts(.rain, on: [5]), hurts(.wind, on: [5])], maximumCauses: 1)
        #expect(result == join(good(goodDays(weak: [5])), heldBack(by: [.rain], on: [5])))
    }

    @Test("A maximum below one lists no causes, so the weak days are neither phrased nor mentioned", arguments: [0, -1])
    func noCauses(maximumCauses: Int) {
        let dayRanges = LabelledDayRanges()

        let result = reason(week(weak: [5]), factors: [hurts(.rain, on: [5])], maximumCauses: maximumCauses, dayRanges: dayRanges)

        #expect(result == good(goodDays(weak: [5])))
        #expect(dayRanges.requestedIndices == [goodDays(weak: [5])])
    }

    @Test("A snowfall block reads as not enough snow")
    func snowfallBlocker() {
        let result = reason(week(blocked: allDays, by: .snowfall))
        #expect(result == String(localized: .reasonBlockedSnowfall(label(allDays))))
    }

    @Test("A thunderstorm block reads as thunderstorms")
    func thunderstormBlocker() {
        let result = reason(week(blocked: allDays, by: .thunderstorm))
        #expect(result == String(localized: .reasonBlockedThunderstorm(label(allDays))))
    }

    @Test("Any other block reads as not suitable", arguments: [Factor.Kind.wind, .rain, .temperature])
    func otherBlocker(kind: Factor.Kind) {
        let result = reason(week(blocked: allDays, by: kind))
        #expect(result == String(localized: .reasonBlockedOther(label(allDays))))
    }

    @Test("A negative clause whose days cannot be phrased is left out")
    func unphrasedClause() {
        let assessments = week(blocked: [5], weak: [6])
        let factors = [hurts(.rain, on: [6])]
        let positive = good(goodDays(blocked: [5], weak: [6]))

        let withoutBlocked = reason(assessments, factors: factors, dayRanges: LabelledDayRanges(unphrased: [[5]]))
        let withoutHeldBack = reason(assessments, factors: factors, dayRanges: LabelledDayRanges(unphrased: [[6]]))

        #expect(withoutBlocked == join(positive, heldBack(by: [.rain], on: [6])))
        #expect(withoutHeldBack == join(positive, String(localized: .reasonBlockedThunderstorm(label([5])))))
    }

    @Test("Weak days without a cause fall back to the best day")
    func peak() {
        let dayRanges = LabelledDayRanges()
        let assessments = [scored(30), scored(45), scored(52), scored(52), scored(20), scored(10), scored(40)]

        let result = reason(assessments, factors: [Factor(kind: .rain, effect: .helps, days: allDays)], dayRanges: dayRanges)

        #expect(result == String(localized: .reasonPeak(format.weekday(days[2].date), 52)))
        #expect(dayRanges.requestedIndices == [[]])
    }

    @Test("An outlook without days, or a forecast without days, is not suitable all week")
    func emptyFallback() {
        let expected = String(localized: .reasonBlockedOther(String(localized: .dayAllWeek)))
        #expect(reason([]) == expected)
        #expect(reason(week(), days: []) == expected)
    }

    @Test("Assessments beyond the forecast's days are ignored")
    func extraAssessments() {
        let dayRanges = LabelledDayRanges()
        let forecast = Array(days.prefix(5))

        let result = reason(week(weak: [5, 6]), factors: [hurts(.rain, on: [5, 6])], dayRanges: dayRanges, days: forecast)

        #expect(result == good([0, 1, 2, 3, 4]))
        #expect(dayRanges.requests == [LabelledDayRanges.Request(indices: [0, 1, 2, 3, 4], days: forecast)])
    }

    @Test("Blocked days after the forecast's last day do not decide which blocker is named")
    func blockersPastForecast() {
        let forecast = Array(days.prefix(5))
        let assessments = [blocked(.thunderstorm)] + Array(repeating: scored(80), count: 4) + [blocked(.snowfall), blocked(.snowfall)]

        let result = reason(assessments, days: forecast)

        #expect(result == join(good([1, 2, 3, 4]), String(localized: .reasonBlockedThunderstorm(label([0])))))
    }
}
