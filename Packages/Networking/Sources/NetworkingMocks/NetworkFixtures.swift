//
//  NetworkFixtures.swift
//  NetworkingMocks
//
//  Created by Kamil Misiag on 19/10/2026.
//

import Foundation
import Networking

public enum NetworkFixtures {
    public static let baseURL = URL(string: "https://api.example.test/base")!

    public static func response(
        status: Int = 200,
        body: Data = Data(),
        headers: [String: String] = [:],
        retryAfter: String? = nil,
        url: URL? = nil
    ) -> HTTPResponse {
        var headers = headers
        if let retryAfter {
            headers[HTTPHeaderField.retryAfter] = retryAfter
        }
        return HTTPResponse(statusCode: status, headers: headers, body: body, url: url)
    }

    public static func request(method: HTTPMethod, url: URL = baseURL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        return request
    }
}
