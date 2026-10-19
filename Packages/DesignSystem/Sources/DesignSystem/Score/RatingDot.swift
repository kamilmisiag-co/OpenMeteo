//
//  RatingDot.swift
//  DesignSystem
//
//  Created by Kamil Misiag on 19/10/2026.
//

import SwiftUI

public struct RatingDot: View {
    public enum Size: Sendable {
        case small
        case regular
    }

    let rating: Rating
    var size: Size

    @ScaledMetric(relativeTo: .subheadline) private var smallDiameter: CGFloat = 8
    @ScaledMetric(relativeTo: .body) private var regularDiameter: CGFloat = 12

    public init(rating: Rating, size: Size = .regular) {
        self.rating = rating
        self.size = size
    }

    public var body: some View {
        let diameter = size == .small ? smallDiameter : regularDiameter
        Circle()
            .fill(rating.color)
            .frame(width: diameter, height: diameter)
            .accessibilityHidden(true)
    }
}

#Preview("Rating dots") {
    VStack(spacing: 12) {
        HStack(spacing: 12) {
            ForEach(Rating.allCases, id: \.self) { rating in
                RatingDot(rating: rating)
            }
        }
        HStack(spacing: 12) {
            ForEach(Rating.allCases, id: \.self) { rating in
                RatingDot(rating: rating, size: .small)
            }
        }
    }
    .padding()
}
