//
//  NetworkError.swift
//  Networking
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation
import Utils

public enum NetworkError: Error {
    case invalidURL(path: String)
    case encoding(underlying: any Error)
    case transport(URLError)
    case nonHTTPResponse
    case unacceptableStatusCode(HTTPResponse)
    case decoding(underlying: any Error)
}

extension NetworkError: UnderlyingErrorProviding {
    public var underlyingError: (any Error)? {
        switch self {
        case .transport(let error): error
        case .encoding(let error), .decoding(let error): error
        case .invalidURL, .nonHTTPResponse, .unacceptableStatusCode: nil
        }
    }
}
