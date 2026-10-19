//
//  RetryPolicy.swift
//  Networking
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation

public protocol RetryPolicy: Sendable {
    func delay(beforeRetry attempt: Int, of request: URLRequest, after error: NetworkError) -> Duration?
}
