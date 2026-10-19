//
//  NetworkError+Inspection.swift
//  NetworkingMocks
//
//  Created by Kamil Misiag on 19/10/2026.
//

import Foundation
import Networking

extension NetworkError {
    public var caseName: String {
        switch self {
        case .invalidURL: "invalidURL"
        case .encoding: "encoding"
        case .transport: "transport"
        case .nonHTTPResponse: "nonHTTPResponse"
        case .unacceptableStatusCode: "unacceptableStatusCode"
        case .decoding: "decoding"
        }
    }

    public var statusCode: Int? {
        if case .unacceptableStatusCode(let response) = self { response.statusCode } else { nil }
    }

    public var urlErrorCode: URLError.Code? {
        if case .transport(let error) = self { error.code } else { nil }
    }
}
