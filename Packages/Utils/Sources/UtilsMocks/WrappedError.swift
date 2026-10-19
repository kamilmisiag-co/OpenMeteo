//
//  WrappedError.swift
//  UtilsMocks
//
//  Created by Kamil Misiag on 19/10/2026.
//

import Utils

public struct WrappedError: UnderlyingErrorProviding {
    public let underlyingError: (any Error)?

    public init(underlyingError: (any Error)?) {
        self.underlyingError = underlyingError
    }
}
