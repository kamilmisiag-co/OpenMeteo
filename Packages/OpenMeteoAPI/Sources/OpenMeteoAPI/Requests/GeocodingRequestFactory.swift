//
//  GeocodingRequestFactory.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Utils

public struct GeocodingRequestFactory: GeocodingRequestMaking {
    private let resultLimit: Int
    private let languageCodes: any LanguageCodeProviding

    public init(resultLimit: Int, allowedResultLimits: ClosedRange<Int>, languageCodes: any LanguageCodeProviding) {
        self.resultLimit = resultLimit.clamped(to: allowedResultLimits)
        self.languageCodes = languageCodes
    }

    public func request(forName name: String) -> GeocodingEndpoint {
        GeocodingEndpoint(name: name, resultLimit: resultLimit, languageCode: languageCodes.languageCode())
    }
}
