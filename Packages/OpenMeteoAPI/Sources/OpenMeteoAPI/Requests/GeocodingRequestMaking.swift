//
//  GeocodingRequestMaking.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

public protocol GeocodingRequestMaking: Sendable {
    func request(forName name: String) -> GeocodingEndpoint
}
