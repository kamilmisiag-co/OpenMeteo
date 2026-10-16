//
//  Rating.swift
//  DesignSystem
//
//  Created by Kamil Misiag on 15/10/2026.
//

import SwiftUI

nonisolated public enum Rating: CaseIterable, Hashable, Sendable {
    case excellent
    case good
    case fair
    case poor
    case notSuitable

    public init(score: Int?) {
        guard let score else {
            self = .notSuitable
            return
        }
        switch score {
        case 80...: self = .excellent
        case 60..<80: self = .good
        case 40..<60: self = .fair
        default: self = .poor
        }
    }

    public var range: ClosedRange<Int>? {
        switch self {
        case .excellent: 80...100
        case .good: 60...79
        case .fair: 40...59
        case .poor: 0...39
        case .notSuitable: nil
        }
    }
}

extension Rating {
    public var color: Color {
        switch self {
        case .excellent: .green
        case .good: .mint
        case .fair: .orange
        case .poor: .red
        case .notSuitable: .gray
        }
    }

    public var title: LocalizedStringResource {
        switch self {
        case .excellent: .ratingExcellent
        case .good: .ratingGood
        case .fair: .ratingFair
        case .poor: .ratingPoor
        case .notSuitable: .ratingNotSuitable
        }
    }

    public var rangeText: String? {
        range.map { "\($0.lowerBound == 0 ? 1 : $0.lowerBound)–\($0.upperBound)" }
    }
}
