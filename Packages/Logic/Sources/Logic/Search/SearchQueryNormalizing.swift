//
//  SearchQueryNormalizing.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public protocol SearchQueryNormalizing: Sendable {
    func normalizedQuery(from rawQuery: String) -> String?
}
