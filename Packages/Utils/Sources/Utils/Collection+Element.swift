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
}
