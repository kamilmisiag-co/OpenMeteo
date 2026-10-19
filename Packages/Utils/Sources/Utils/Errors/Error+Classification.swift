//
//  Error+Classification.swift
//  Utils
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation

public protocol UnderlyingErrorProviding: Error {
    var underlyingError: (any Error)? { get }
}

private enum ErrorChain {
    static let maximumDepth = 16
    static let connectivityCodes: Set<URLError.Code> = [
        .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed,
        .internationalRoamingOff, .cannotConnectToHost, .cannotFindHost, .timedOut,
    ]
}

extension Error {
    public var isCancellation: Bool {
        if self is CancellationError || (self as? URLError)?.code == .cancelled {
            return true
        }
        return underlyingErrors.contains { $0 is CancellationError }
    }

    public var isConnectivity: Bool {
        ([self] + underlyingErrors).contains { error in
            (error as? URLError).map { ErrorChain.connectivityCodes.contains($0.code) } ?? false
        }
    }

    private var underlyingErrors: [any Error] {
        var chain: [any Error] = []
        var current: any Error = self
        while chain.count < ErrorChain.maximumDepth,
              let next = (current as? any UnderlyingErrorProviding)?.underlyingError {
            chain.append(next)
            current = next
        }
        return chain
    }
}
