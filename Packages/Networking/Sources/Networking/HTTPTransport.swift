//
//  HTTPTransport.swift
//  Networking
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation

public protocol HTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> HTTPResponse
}
