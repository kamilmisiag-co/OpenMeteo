//
//  Comparable+Clamped.swift
//  Utils
//
//  Created by Kamil Misiag on 16/10/2026.
//

extension Comparable {
    public func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
