//
//  RequestBuilding.swift
//  Networking
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation

public protocol RequestBuilding: Sendable {
    func makeRequest<E: Endpoint>(for endpoint: E) throws -> URLRequest
}

public struct RequestBuilder: RequestBuilding {
    private static let queryComponentAllowed = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "&=+"))

    private let configuration: RequestConfiguration
    private let bodyEncoder: any BodyEncoding

    public init(configuration: RequestConfiguration, bodyEncoder: any BodyEncoding) {
        self.configuration = configuration
        self.bodyEncoder = bodyEncoder
    }

    public func makeRequest<E: Endpoint>(for endpoint: E) throws -> URLRequest {
        var request = URLRequest(
            url: try url(for: endpoint),
            cachePolicy: configuration.cachePolicy,
            timeoutInterval: configuration.timeout / .seconds(1)
        )
        request.httpMethod = endpoint.method.rawValue
        for (field, value) in configuration.defaultHeaders {
            request.setValue(value, forHTTPHeaderField: field)
        }
        if let body = endpoint.body {
            let encoded = try encode(body)
            request.httpBody = encoded.data
            request.setValue(encoded.contentType, forHTTPHeaderField: HTTPHeaderField.contentType)
        }
        for (field, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: field)
        }
        return request
    }

    private func url<E: Endpoint>(for endpoint: E) throws -> URL {
        let joined = endpoint.path.isEmpty ? configuration.baseURL : configuration.baseURL.appending(path: endpoint.path)
        guard var components = URLComponents(url: joined, resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidURL(path: endpoint.path)
        }
        if !endpoint.queryItems.isEmpty {
            let encodedItems = try endpoint.queryItems.map { try percentEncoded($0, path: endpoint.path) }
            components.percentEncodedQueryItems = (components.percentEncodedQueryItems ?? []) + encodedItems
        }
        guard let url = components.url else {
            throw NetworkError.invalidURL(path: endpoint.path)
        }
        return url
    }

    private func percentEncoded(_ item: URLQueryItem, path: String) throws -> URLQueryItem {
        guard let name = item.name.addingPercentEncoding(withAllowedCharacters: Self.queryComponentAllowed) else {
            throw NetworkError.invalidURL(path: path)
        }
        guard let value = item.value else {
            return URLQueryItem(name: name, value: nil)
        }
        guard let encodedValue = value.addingPercentEncoding(withAllowedCharacters: Self.queryComponentAllowed) else {
            throw NetworkError.invalidURL(path: path)
        }
        return URLQueryItem(name: name, value: encodedValue)
    }

    private func encode(_ body: RequestBody) throws -> (data: Data, contentType: String) {
        switch body {
        case .data(let data, let contentType):
            (data, contentType)
        case .encodable(let value):
            (try bodyEncoder.encode(value), bodyEncoder.contentType)
        }
    }
}
