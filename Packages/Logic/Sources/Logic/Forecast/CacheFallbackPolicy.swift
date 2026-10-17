//
//  CacheFallbackPolicy.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public protocol CacheFallbackPolicy: Sendable {
    func allowsCachedForecast(after error: any Error) -> Bool
}
