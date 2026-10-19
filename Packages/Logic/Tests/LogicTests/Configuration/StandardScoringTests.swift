//
//  StandardScoringTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic
import LogicMocks
import Testing

@Suite("Standard scoring presets")
struct StandardScoringTests {
    @Test("There's one preset scorer per activity")
    func presets() {
        #expect(StandardRules.scorers.map(\.activity) == Activity.allCases)
    }

    @Test("Every preset scorer keeps its scores between 0 and 100 across extreme weather")
    func scoresStayInRange() {
        let extremes = [
            LogicFixtures.day(condition: .clear, high: 45, low: 30, rain: 0, wind: 0, gusts: 0, snowfall: 0, snowDepth: 0),
            LogicFixtures.day(condition: .snow, high: -25, low: -40, rain: 1, wind: 90, gusts: 140, snowfall: 80, snowDepth: 300),
            LogicFixtures.day(condition: .rain, high: 12, low: 8, rain: nil, wind: 60, gusts: 100),
            LogicFixtures.day(condition: .thunderstorm, high: 30, low: 22, rain: 1, wind: 40, gusts: 90),
            LogicFixtures.day(condition: .fog, high: 0, low: 0, rain: 0.5, wind: 5, gusts: 5, snowfall: 2, snowDepth: 40),
        ]
        for scorer in StandardRules.scorers {
            let scores = scorer.assess(extremes).compactMap(\.score)
            #expect(!scores.isEmpty, "\(scorer.activity) scored no day")
            #expect(scores.allSatisfy { (0...100).contains($0) }, "\(scorer.activity) scored \(scores)")
        }
    }

    @Test("A sunny, mild, calm day is for sightseeing outdoors rather than indoors")
    func sunnyDay() throws {
        let day = [LogicFixtures.day(condition: .clear, high: 22, low: 14, rain: 0.05, wind: 8, gusts: 18)]
        let outdoor = try #require(StandardRules.outdoorSightseeing.assess(day).first)
        let indoor = try #require(StandardRules.indoorSightseeing.assess(day).first)
        #expect(try #require(outdoor.score) >= 80)
        #expect(try #require(indoor.score) <= 40)
        #expect(outdoor.effects == [.rain: .helps, .temperature: .helps, .wind: .helps])
        #expect(indoor.effects == [.rain: .hurts, .temperature: .hurts, .wind: .hurts])
    }

    @Test("A cool day with likely rain and strong wind is for sightseeing indoors")
    func wetWindyDay() {
        let day = [LogicFixtures.day(condition: .rain, high: 16, low: 9, rain: 0.8, wind: 32, gusts: 55)]
        #expect(StandardRules.outdoorSightseeing.assess(day) == [DayAssessment(score: 38, effects: [.rain: .hurts, .temperature: .helps])])
        #expect(StandardRules.indoorSightseeing.assess(day) == [DayAssessment(score: 74, effects: [.rain: .helps, .temperature: .hurts])])
    }

    @Test("Skiing is ruled out without snow on the ground or falling")
    func skiingWithoutSnow() {
        let bare = LogicFixtures.day(high: -4, low: -11, snowfall: 0, snowDepth: nil)
        let thin = LogicFixtures.day(high: -4, low: -11, snowfall: 0.5, snowDepth: 6)
        #expect(StandardRules.skiing.assess([bare, thin]).map(\.blocker) == [.snowfall, .snowfall])
        #expect(StandardRules.skiing.assess([bare, thin]).map(\.score) == [nil, nil])
    }

    @Test("A cold day on deep snow with fresh powder is good for skiing")
    func skiingDay() throws {
        let day = [LogicFixtures.day(condition: .snow, high: -5, low: -12, rain: 0.6, wind: 15, gusts: 30, snowfall: 8, snowDepth: 30)]
        let score = try #require(StandardRules.skiing.assess(day).first?.score)
        #expect(score >= 60)
    }

    @Test("Precipitation on a freezing ski day counts as snow, not rain")
    func skiingRainAsSnow() {
        let freezing = [LogicFixtures.day(condition: .snow, high: 0, low: -6, rain: 0.9, snowfall: 4, snowDepth: 30)]
        let thawing = [LogicFixtures.day(condition: .rain, high: 3, low: -1, rain: 0.9, snowfall: 0, snowDepth: 30)]
        #expect(StandardRules.skiing.assess(freezing).first?.effects[.rain] == .helps)
        #expect(StandardRules.skiing.assess(thawing).first?.effects[.rain] == .hurts)
    }

    @Test("A thunderstorm rules out surfing, but rain alone doesn't")
    func surfingThunderstorm() {
        let storm = [LogicFixtures.day(condition: .thunderstorm, high: 26, low: 19, rain: 0.9, wind: 12, gusts: 20)]
        let shower = [LogicFixtures.day(condition: .rain, high: 26, low: 19, rain: 0.9, wind: 12, gusts: 20)]
        #expect(StandardRules.surfing.assess(storm).first?.blocker == .thunderstorm)
        #expect(StandardRules.surfing.assess(shower).first?.score != nil)
    }

    @Test("Surfing favours warm days with light wind")
    func surfingWind() {
        let calm = [LogicFixtures.day(high: 24, low: 17, rain: 0.1, wind: 10, gusts: 20)]
        let gale = [LogicFixtures.day(high: 24, low: 17, rain: 0.1, wind: 45, gusts: 70)]
        #expect(StandardRules.surfing.assess(calm) == [DayAssessment(score: 100, effects: [.wind: .helps, .temperature: .helps, .rain: .helps])])
        #expect(StandardRules.surfing.assess(gale) == [DayAssessment(score: 55, effects: [.wind: .hurts, .temperature: .helps, .rain: .helps])])
    }
}
