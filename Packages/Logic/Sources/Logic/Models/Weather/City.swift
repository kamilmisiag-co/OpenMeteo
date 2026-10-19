//
//  City.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation

public struct City: Identifiable, Hashable, Codable, Sendable {
    public let id: Int
    public let name: String
    public let region: String?
    public let country: String
    public let countryCode: String?
    public let latitude: Double
    public let longitude: Double
    public let timeZoneIdentifier: String?

    public init(
        id: Int,
        name: String,
        region: String?,
        country: String,
        countryCode: String?,
        latitude: Double,
        longitude: Double,
        timeZoneIdentifier: String?
    ) {
        self.id = id
        self.name = name
        self.region = region
        self.country = country
        self.countryCode = countryCode
        self.latitude = latitude
        self.longitude = longitude
        self.timeZoneIdentifier = timeZoneIdentifier
    }

    public var timeZone: TimeZone? {
        timeZoneIdentifier.flatMap(TimeZone.init(identifier:))
    }
}
