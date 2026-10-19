//
//  Sequence+MostFrequentCase.swift
//  Utils
//
//  Created by Kamil Misiag on 18/10/2026.
//

extension Sequence where Element: CaseIterable & Hashable {
    public func mostFrequentCase() -> Element? {
        let counts = reduce(into: [Element: Int]()) { counts, value in
            counts[value, default: 0] += 1
        }
        var winner: (value: Element, count: Int)?
        for candidate in Element.allCases {
            let count = counts[candidate, default: 0]
            if count > (winner?.count ?? 0) {
                winner = (candidate, count)
            }
        }
        return winner?.value
    }
}
