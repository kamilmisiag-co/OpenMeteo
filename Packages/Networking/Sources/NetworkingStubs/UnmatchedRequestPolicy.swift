//
//  UnmatchedRequestPolicy.swift
//  NetworkingStubs
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation

public enum UnmatchedRequestPolicy: Hashable, Sendable {
    case fail(URLError.Code)
    case respond(StubResponse)
}
