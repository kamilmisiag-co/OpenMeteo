//
//  RatingTests.swift
//  DesignSystemTests
//
//  Created by Kamil Misiag on 15/10/2026.
//

import DesignSystem
import Testing

@MainActor
@Suite("Rating")
struct RatingTests {
    @Test("Scores map to the rating scale", arguments: zip(
        [100, 80, 79, 60, 59, 40, 39, 1, 0],
        [Rating.excellent, .excellent, .good, .good, .fair, .fair, .poor, .poor, .poor]
    ))
    func mapsScore(score: Int, expected: Rating) {
        #expect(Rating(score: score) == expected)
    }

    @Test("Scores outside 0–100 take the rating at the nearer end of the scale", arguments: zip(
        [101, 250, -1, -40],
        [Rating.excellent, .excellent, .poor, .poor]
    ))
    func clampsOutOfRangeScore(score: Int, expected: Rating) {
        #expect(Rating(score: score) == expected)
    }

    @Test("A missing score is a hard blocker, not a low score")
    func nilIsNotSuitable() {
        #expect(Rating(score: nil) == .notSuitable)
        #expect(Rating.notSuitable.range == nil)
        #expect(Rating.notSuitable.rangeText == nil)
    }

    @Test("Range text matches the How scores legend, with Poor shown as 1–39")
    func rangeText() {
        #expect(Rating.allCases.map(\.rangeText) == ["80–100", "60–79", "40–59", "1–39", nil])
    }
}
