//
//  RequestInterceptor.swift
//  Networking
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation

public protocol RequestInterceptor: Sendable {
    func intercept(_ request: URLRequest) async throws -> URLRequest
}
