//
//  ActivityDetailBar.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

struct ActivityDetailBar: Identifiable, Hashable {
    let id: Int
    let label: String
    let calloutTitle: String
    let accessibilityLabel: String
    let score: Int?
    let isBest: Bool
}
