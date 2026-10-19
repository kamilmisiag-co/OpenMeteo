//
//  NoRetryPolicy.swift
//  Networking
//
//  Created by Kamil Misiag on 19/10/2026.
//

import Foundation

public struct NoRetryPolicy: RetryPolicy {
    public init() {}

    public func delay(beforeRetry attempt: Int, of request: URLRequest, after error: NetworkError) -> Duration? {
        nil
    }
}
