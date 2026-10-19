//
//  Sequence+MinAndMax.swift
//  Utils
//
//  Created by Kamil Misiag on 18/10/2026.
//

extension Sequence where Element: Comparable {
    public func minAndMax() -> (min: Element, max: Element)? {
        reduce(into: nil) { bounds, value in
            guard let current = bounds else {
                bounds = (value, value)
                return
            }
            bounds = (Swift.min(current.min, value), Swift.max(current.max, value))
        }
    }
}
