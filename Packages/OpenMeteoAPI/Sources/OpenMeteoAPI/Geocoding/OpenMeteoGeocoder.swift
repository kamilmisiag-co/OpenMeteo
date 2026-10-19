//
//  OpenMeteoGeocoder.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic
import Networking

public struct OpenMeteoGeocoder: CityGeocoding {
    private let client: any HTTPClient
    private let requests: any GeocodingRequestMaking
    private let mapper: any CityMapping

    public init(client: any HTTPClient, requests: any GeocodingRequestMaking, mapper: any CityMapping) {
        self.client = client
        self.requests = requests
        self.mapper = mapper
    }

    public func cities(named name: String) async throws -> [City] {
        try await client.send(requests.request(forName: name)).results.compactMap { mapper.city(from: $0) }
    }
}
