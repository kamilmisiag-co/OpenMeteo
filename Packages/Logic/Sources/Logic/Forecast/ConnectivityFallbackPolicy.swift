//
//  ConnectivityFallbackPolicy.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Utils

public struct ConnectivityFallbackPolicy: CacheFallbackPolicy {
    public init() {}

    public func allowsCachedForecast(after error: any Error) -> Bool {
        error.isConnectivity && !error.isCancellation
    }
}
