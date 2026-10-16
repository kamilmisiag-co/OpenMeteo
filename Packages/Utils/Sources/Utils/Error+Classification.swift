//
//  Error+Classification.swift
//  Utils
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation

extension Error {
    public var isCancellation: Bool {
        self is CancellationError || (self as? URLError)?.code == .cancelled
    }

    public var isConnectivity: Bool {
        guard let code = (self as? URLError)?.code else { return false }
        let connectivityCodes: Set<URLError.Code> = [
            .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed,
            .internationalRoamingOff, .cannotConnectToHost, .cannotFindHost, .timedOut,
        ]
        return connectivityCodes.contains(code)
    }
}
