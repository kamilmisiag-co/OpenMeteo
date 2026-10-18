//
//  ActivityDetailDay.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

struct ActivityDetailDay: Identifiable, Hashable {
    let id: Int
    let label: String
    let symbolName: String
    let conditionTitle: String
    let high: String
    let low: String
    let score: Int?
    let caption: String
    let isBest: Bool
}
