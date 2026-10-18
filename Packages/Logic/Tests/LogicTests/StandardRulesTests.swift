//
//  StandardRulesTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic
import Testing

@Suite("Standard rule values the app ships with")
struct StandardRulesTests {
    @Test("Searches wait 250 ms after typing stops and need at least two characters")
    func searchTiming() {
        #expect(StandardRules.searchDebounce == .milliseconds(250))
        #expect(StandardRules.minimumQueryLength == 2)
    }

    @Test("A query ends at a comma typed on any of the supported keyboards")
    func querySeparators() {
        #expect(StandardRules.querySeparators == [",", "，", "、", "､", "﹐", "﹑", "،"])
    }

    @Test("Zero-width spaces and byte order marks are removed from a query")
    func queryInvisibleScalars() {
        #expect(StandardRules.queryInvisibleScalars == ["\u{200B}", "\u{FEFF}"])
    }

    @Test("Up to ten recent cities are remembered")
    func maximumRecentCities() {
        #expect(StandardRules.maximumRecentCities == 10)
    }

    @Test("A forecast covers seven days and a live one turns stale three hours after it was fetched")
    func forecastWindow() {
        #expect(StandardRules.forecastDayCount == 7)
        #expect(StandardRules.staleAfter == .seconds(3 * 60 * 60))
    }

    @Test("A score of 60 or more counts as strong")
    func strongScoreThreshold() {
        #expect(StandardRules.strongScoreThreshold == 60)
    }

    @Test("Activities with equal scores are ranked surfing, outdoor sightseeing, indoor sightseeing, then skiing")
    func tieBreakOrder() {
        #expect(StandardRules.tieBreakOrder == [.surfing, .outdoorSightseeing, .indoorSightseeing, .skiing])
    }
}
