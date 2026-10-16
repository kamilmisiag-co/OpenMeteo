//
//  ForecastStrip.swift
//  DesignSystem
//
//  Created by Kamil Misiag on 15/10/2026.
//

import SwiftUI

public struct ForecastStripDay: Identifiable, Hashable, Sendable {
    public let id: Int
    public let label: String
    public let symbolName: String
    public let high: String
    public let low: String
    public let precipitation: String?
    public let accessibilityLabel: String

    public init(id: Int, label: String, symbolName: String, high: String, low: String, precipitation: String?, accessibilityLabel: String) {
        self.id = id
        self.label = label
        self.symbolName = symbolName
        self.high = high
        self.low = low
        self.precipitation = precipitation
        self.accessibilityLabel = accessibilityLabel
    }
}

public struct ForecastStrip: View {
    let days: [ForecastStripDay]
    @Binding var selection: Int?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .subheadline) private var scrollingColumnWidth: CGFloat = 64

    public init(days: [ForecastStripDay], selection: Binding<Int?>) {
        self.days = days
        _selection = selection
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(.forecastStripTitle)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 8)
                .accessibilityAddTraits(.isHeader)

            if dynamicTypeSize.isAccessibilitySize {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(days) { day in
                            column(day).frame(width: scrollingColumnWidth)
                        }
                    }
                }
            } else {
                HStack(spacing: 2) {
                    ForEach(days) { day in
                        column(day).frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func column(_ day: ForecastStripDay) -> some View {
        let isSelected = selection == day.id
        return Button {
            selection = isSelected ? nil : day.id
        } label: {
            VStack(spacing: 3) {
                Text(day.label)
                    .font(.subheadline.weight(isSelected ? .bold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Image(systemName: day.symbolName)
                    .symbolRenderingMode(.multicolor)
                    .font(.title3)
                    .frame(minHeight: 28)
                Text(day.high)
                    .font(.subheadline.weight(.semibold))
                Text(day.low)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(day.precipitation ?? " ")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tint)
            }
            .monospacedDigit()
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.accentColor.opacity(0.15))
                }
            }
            .contentShape(.rect(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(day.accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint(Text(.forecastStripHint))
        .accessibilityIdentifier("forecast.day.\(day.id)")
    }
}

#Preview("Forecast strip") {
    @Previewable @State var selection: Int? = 5
    let symbols = ["cloud.sun.fill", "sun.max.fill", "cloud.sun.fill", "cloud.sun.fill", "cloud.fill", "cloud.rain.fill", "cloud.rain.fill"]
    let labels = ["Today", "Fri", "Sat", "Sun", "Mon", "Tue", "Wed"]
    let days = labels.indices.map { index in
        ForecastStripDay(
            id: index,
            label: labels[index],
            symbolName: symbols[index],
            high: "\(24 - index / 2)°",
            low: "\(16 - index / 3)°",
            precipitation: index >= 5 ? "80%" : nil,
            accessibilityLabel: labels[index]
        )
    }
    List {
        ForecastStrip(days: days, selection: $selection)
    }
}
