//
//  Endpoint.swift
//  Networking
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation
import Utils

public protocol Endpoint: Sendable {
    associatedtype Response: Sendable

    var method: HTTPMethod { get }
    var path: String { get }
    var queryItems: [URLQueryItem] { get }
    var headers: [String: String] { get }
    var body: RequestBody? { get }

    func decode(_ response: HTTPResponse, using decoder: any DataDecoding) throws -> Response
}

extension Endpoint {
    public var queryItems: [URLQueryItem] { [] }
    public var headers: [String: String] { [:] }
    public var body: RequestBody? { nil }
}

extension Endpoint where Response: Decodable {
    public func decode(_ response: HTTPResponse, using decoder: any DataDecoding) throws -> Response {
        do {
            return try decoder.decode(Response.self, from: response.body)
        } catch {
            throw NetworkError.decoding(underlying: error)
        }
    }
}

extension Endpoint where Response == Data {
    public func decode(_ response: HTTPResponse, using decoder: any DataDecoding) throws -> Data {
        response.body
    }
}

extension Endpoint where Response == EmptyResponse {
    public func decode(_ response: HTTPResponse, using decoder: any DataDecoding) throws -> EmptyResponse {
        EmptyResponse()
    }
}
