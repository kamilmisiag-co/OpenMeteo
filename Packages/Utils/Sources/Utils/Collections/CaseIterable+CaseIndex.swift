//
//  CaseIterable+CaseIndex.swift
//  Utils
//
//  Created by Kamil Misiag on 19/10/2026.
//

extension CaseIterable where Self: Equatable {
    public var caseIndex: Int {
        let cases = Self.allCases
        guard let index = cases.firstIndex(of: self) else { return cases.count }
        return cases.distance(from: cases.startIndex, to: index)
    }
}
