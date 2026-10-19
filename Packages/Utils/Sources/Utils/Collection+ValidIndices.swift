//
//  Collection+ValidIndices.swift
//  Utils
//
//  Created by Kamil Misiag on 18/10/2026.
//

extension Collection where Indices == Range<Index>, Index: Hashable {
    public func validIndices(among candidates: some Sequence<Index>) -> [Index] {
        Set(candidates).filter(indices.contains).sorted()
    }
}
