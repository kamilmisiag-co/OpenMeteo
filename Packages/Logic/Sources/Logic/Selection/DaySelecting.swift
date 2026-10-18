//
//  DaySelecting.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public protocol DaySelecting: Sendable {
    func selection(afterChoosing day: Int?, current: Int?, dayCount: Int) -> Int?
}
