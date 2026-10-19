//
//  Collection+Element.swift
//  Utils
//
//  Created by Kamil Misiag on 18/10/2026.
//

extension Collection where Indices == Range<Index> {
    public func element(at index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }

    public func validIndex(_ index: Index?) -> Index? {
        guard let index, indices.contains(index) else { return nil }
        return index
    }
}
