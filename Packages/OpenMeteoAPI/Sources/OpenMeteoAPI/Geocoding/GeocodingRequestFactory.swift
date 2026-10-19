//
//  GeocodingRequestFactory.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

public protocol GeocodingRequestMaking: Sendable {
    func request(forName name: String) -> GeocodingEndpoint
}

public struct GeocodingRequestFactory: GeocodingRequestMaking {
    private let resultLimit: Int
    private let languageCodes: any LanguageCodeProviding

    public init(resultLimit: Int, languageCodes: any LanguageCodeProviding) {
        self.resultLimit = resultLimit
        self.languageCodes = languageCodes
    }

    public func request(forName name: String) -> GeocodingEndpoint {
        GeocodingEndpoint(name: name, resultLimit: resultLimit, languageCode: languageCodes.languageCode())
    }
}
