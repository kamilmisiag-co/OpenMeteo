//
//  ComponentSnapshotTests.swift
//  DesignSystemTests
//
//  Created by Kamil Misiag on 15/10/2026.
//

import DesignSystem
import SwiftUI
import Testing

@MainActor
@Suite("Component snapshots")
struct ComponentSnapshotTests {
    private let week: [Int?] = [82, 86, 92, 88, 80, 52, 66]
    private let initials = ["T", "F", "S", "S", "M", "T", "W"]

    @Test func scoreRing() {
        assertComponent(
            VStack(spacing: 16) {
                HStack(spacing: 20) {
                    ScoreRing(score: 78)
                    ScoreRing(score: 48)
                    ScoreRing(score: nil)
                }
                HStack(spacing: 20) {
                    ScoreRing(score: 78, size: .large)
                    ScoreRing(score: nil, size: .large)
                }
            }
        )
    }

    @Test func scorePill() {
        assertComponent(
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ScorePill(score: 92)
                    ScorePill(score: 72)
                }
                HStack {
                    ScorePill(score: 48)
                    ScorePill(score: 30)
                }
                HStack {
                    ScorePill(score: nil)
                    ScorePill(score: 92, style: .scoreOnly)
                    ScorePill(score: nil, style: .scoreOnly)
                    ScorePill(score: 78, style: .wordOnly)
                }
            }
        )
    }

    @Test func dailyBars() {
        assertComponent(
            VStack(alignment: .leading, spacing: 24) {
                DailyBars(scores: week, initials: initials)
                DailyBars(scores: week, selectedIndex: 5, initials: initials)
                DailyBars(scores: week, style: .row)
                DailyBars(scores: [40, nil, 38, 42, nil, 76, 52], style: .row, selectedIndex: 5)
            }
        )
    }

    @Test func activityIcon() {
        assertComponent(
            HStack(spacing: 16) {
                ActivityIcon(systemImage: "figure.surfing", size: .large)
                ActivityIcon(systemImage: "binoculars.fill")
                ActivityIcon(systemImage: "building.columns.fill")
                ActivityIcon(systemImage: "figure.skiing.downhill", isEnabled: false)
            }
        )
    }

    @Test func forecastStrip() {
        let symbols = ["cloud.sun.fill", "sun.max.fill", "cloud.sun.fill", "cloud.sun.fill", "cloud.fill", "cloud.rain.fill", "cloud.rain.fill"]
        let labels = ["Today", "Fri", "Sat", "Sun", "Mon", "Tue", "Wed"]
        let highs = [23, 24, 24, 23, 22, 19, 20]
        let lows = [16, 16, 17, 17, 16, 15, 15]
        let days = labels.indices.map { index in
            ForecastStripDay(
                id: index,
                label: labels[index],
                symbolName: symbols[index],
                high: "\(highs[index])°",
                low: "\(lows[index])°",
                precipitation: index == 5 ? "80%" : index == 6 ? "50%" : nil,
                accessibilityLabel: labels[index]
            )
        }
        assertComponent(
            VStack(spacing: 16) {
                ForecastStrip(days: days, selection: .constant(nil)).listCell()
                ForecastStrip(days: days, selection: .constant(5)).listCell()
            }
        )
    }

    @Test func cityRow() {
        assertComponent(
            VStack(spacing: 8) {
                CityRow(name: "Lisbon", subtitle: "Lisbon, Portugal", flag: "🇵🇹", highlight: "Lis").listCell()
                CityRow(name: "Zakopane", subtitle: "Lesser Poland, Poland", flag: "🇵🇱").listCell()
                CityRow(name: "Atlantis", subtitle: "Ocean", flag: nil).listCell()
            }
        )
    }

    @Test func statusBanner() {
        assertComponent(
            VStack(spacing: 12) {
                StatusBanner(kind: .stale, message: "Forecast from 06:10 · Pull to refresh")
                StatusBanner(kind: .offline, message: "Offline · Forecast from Wed 14, 18:20")
            }
        )
    }

    @Test func attributionFooter() {
        assertComponent(
            VStack(spacing: 16) {
                AttributionFooter(updated: "09:42", link: URL(string: "https://open-meteo.com/"))
                AttributionFooter(link: URL(string: "https://open-meteo.com/"))
            }
        )
    }

    @Test func sectionHeader() {
        assertComponent(
            VStack(spacing: 16) {
                SectionHeader {
                    Text(verbatim: "Recent")
                } trailing: {
                    Button(action: {}) { Text(verbatim: "Clear") }
                }
                SectionHeader {
                    Text(verbatim: "Best on Tue 20")
                } trailing: {
                    Button(action: {}) { Text(verbatim: "Show week") }
                }
                SectionHeader { Text(verbatim: "Results") }
            }
            .font(.title3.bold())
        )
    }

    @Test func topPickCard() {
        assertComponent(
            VStack(spacing: 16) {
                TopPickCard(
                    title: "Surfing",
                    systemImage: "figure.surfing",
                    reason: "Light winds Thu–Mon; windy and wet Tue",
                    score: 78,
                    dailyScores: week,
                    eyebrow: "Top pick",
                    dayInitials: initials,
                    selectedDay: nil,
                    bestDay: "Best day: Sat 17 · 92"
                )
                .listCell()
                TopPickCard(
                    title: "Indoor sightseeing",
                    systemImage: "building.columns.fill",
                    reason: "Rain every day; museums and cafés win",
                    score: 57,
                    dailyScores: [60, 55, 62, 58, 50, 64, 57],
                    eyebrow: "Best available",
                    dayInitials: initials,
                    selectedDay: 5,
                    bestDay: nil
                )
                .listCell()
            }
        )
    }

    @Test func rankingRow() {
        assertComponent(
            VStack(spacing: 8) {
                RankingRow(
                    rank: 2,
                    title: "Outdoor sightseeing",
                    systemImage: "binoculars.fill",
                    reason: "Sunny and 22–24° until Mon; rain Tue",
                    score: 72,
                    dailyScores: [84, 90, 88, 82, 70, 30, 60],
                    selectedDay: nil
                )
                .listCell()
                RankingRow(
                    rank: 3,
                    title: "Indoor sightseeing",
                    systemImage: "building.columns.fill",
                    reason: "Best saved for rainy Tue",
                    score: 48,
                    dailyScores: [40, 36, 38, 42, 52, 76, 52],
                    selectedDay: 5
                )
                .listCell()
                RankingRow(
                    rank: 4,
                    title: "Skiing",
                    systemImage: "figure.skiing.downhill",
                    reason: "No snow forecast; highs 19–24°",
                    score: nil,
                    dailyScores: Array(repeating: nil, count: 7),
                    selectedDay: nil
                )
                .listCell()
            }
        )
    }

    @Test func dayScoreRow() {
        assertComponent(
            VStack(spacing: 8) {
                DayScoreRow(
                    label: "Sat 17", isBest: true, symbolName: "cloud.sun.fill", conditionTitle: "Partly cloudy",
                    high: "24°", low: "17°", score: 92, caption: "Wind 12 km/h · Gusts 20 km/h · Rain 5%"
                )
                .listCell()
                DayScoreRow(
                    label: "Tue 20", isBest: false, symbolName: "cloud.rain.fill", conditionTitle: "Rain",
                    high: "19°", low: "15°", score: 52, caption: "Wind 32 km/h · Gusts 55 km/h · Rain 80%"
                )
                .listCell()
                DayScoreRow(
                    label: "Today", isBest: false, symbolName: "cloud.sun.fill", conditionTitle: "Partly cloudy",
                    high: "23°", low: "16°", score: nil, caption: "Snow 0 cm · High 23°"
                )
                .listCell()
            }
        )
    }

    @Test func factorRow() {
        assertComponent(
            VStack(spacing: 8) {
                FactorRow(title: "Wind", summary: "Light Thu–Mon, strong Tue", value: "10–32 km/h", helps: false).listCell()
                FactorRow(title: "Air temperature", summary: "Mild all week", value: "15–24°", helps: true).listCell()
                FactorRow(title: "Thunderstorms", summary: "None forecast", value: nil, helps: true).listCell()
            }
        )
    }
}
