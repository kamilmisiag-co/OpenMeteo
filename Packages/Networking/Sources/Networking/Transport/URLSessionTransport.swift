//
//  URLSessionTransport.swift
//  Networking
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation

public protocol HTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> HTTPResponse
}

public struct URLSessionTransport: HTTPTransport {
    private let loader: any URLSessionDataLoading

    public init(loader: any URLSessionDataLoading) {
        self.loader = loader
    }

    public func send(_ request: URLRequest) async throws -> HTTPResponse {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await loader.load(request)
        } catch let error as URLError {
            if error.code == .cancelled, Task.isCancelled { throw CancellationError() }
            throw NetworkError.transport(error)
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.nonHTTPResponse
        }
        return HTTPResponse(
            statusCode: httpResponse.statusCode,
            headers: headers(of: httpResponse),
            body: data,
            url: httpResponse.url
        )
    }

    private func headers(of response: HTTPURLResponse) -> [String: String] {
        response.allHeaderFields.reduce(into: [:]) { headers, field in
            if let name = field.key as? String, let value = field.value as? String {
                headers[name] = value
            }
        }
    }
}
