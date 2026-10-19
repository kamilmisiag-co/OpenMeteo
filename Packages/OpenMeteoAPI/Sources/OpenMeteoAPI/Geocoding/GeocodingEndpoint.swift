//
//  GeocodingEndpoint.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Networking

public struct GeocodingEndpoint: Endpoint {
    public typealias Response = GeocodingResponseDTO

    public let name: String
    public let resultLimit: Int
    public let languageCode: String

    public init(name: String, resultLimit: Int, languageCode: String) {
        self.name = name
        self.resultLimit = resultLimit
        self.languageCode = languageCode
    }

    public var method: HTTPMethod { .get }
    public var path: String { "v1/search" }

    public var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "name", value: name),
            URLQueryItem(name: "count", value: String(resultLimit)),
            URLQueryItem(name: "language", value: languageCode),
            URLQueryItem(name: "format", value: "json"),
        ]
    }
}
