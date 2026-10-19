//
//  Sequence+ConsecutiveRuns.swift
//  Utils
//
//  Created by Kamil Misiag on 18/10/2026.
//

extension Sequence where Element: BinaryInteger {
    public func consecutiveRuns() -> [ClosedRange<Element>] {
        Set(self).sorted().reduce(into: []) { runs, value in
            if let last = runs.last, value - 1 == last.upperBound {
                runs[runs.count - 1] = last.lowerBound...value
            } else {
                runs.append(value...value)
            }
        }
    }
}
