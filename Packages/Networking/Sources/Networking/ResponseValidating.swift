//
//  ResponseValidating.swift
//  Networking
//
//  Created by Kamil Misiag on 16/10/2026.
//

public protocol ResponseValidating: Sendable {
    func validate(_ response: HTTPResponse) throws
}

public struct StatusCodeValidator: ResponseValidating {
    private let acceptableStatusCodes: Range<Int>

    public init(acceptableStatusCodes: Range<Int>) {
        self.acceptableStatusCodes = acceptableStatusCodes
    }

    public func validate(_ response: HTTPResponse) throws {
        guard acceptableStatusCodes.contains(response.statusCode) else {
            throw NetworkError.unacceptableStatusCode(response)
        }
    }
}
