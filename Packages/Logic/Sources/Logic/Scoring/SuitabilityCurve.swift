//
//  SuitabilityCurve.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public protocol SuitabilityCurve: Sendable {
    func suitability(of value: Double) -> Double
}
