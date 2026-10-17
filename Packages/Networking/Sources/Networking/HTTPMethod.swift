//
//  HTTPMethod.swift
//  Networking
//
//  Created by Kamil Misiag on 16/10/2026.
//

public enum HTTPMethod: String, Codable, CaseIterable, Hashable, Sendable {
    case get = "GET"
    case head = "HEAD"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
    case options = "OPTIONS"
}
