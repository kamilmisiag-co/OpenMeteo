//
//  GeocodingResultDTO.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

public struct GeocodingResultDTO: Decodable, Hashable, Sendable {
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case latitude
        case longitude
        case countryCode = "country_code"
        case country
        case admin1
        case timezone
    }

    public let id: Int
    public let name: String
    public let latitude: Double
    public let longitude: Double
    public let countryCode: String?
    public let country: String?
    public let admin1: String?
    public let timezone: String?
}
