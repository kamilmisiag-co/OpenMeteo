//
//  GeocodingCityMapper.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import Logic

public struct GeocodingCityMapper: CityMapping {
    private let regionNames: any RegionNameProviding

    public init(regionNames: any RegionNameProviding) {
        self.regionNames = regionNames
    }

    public func city(from result: GeocodingResultDTO) -> City? {
        guard let name = present(result.name) else { return nil }
        let countryCode = present(result.countryCode)?.uppercased()
        return City(
            id: result.id,
            name: name,
            region: present(result.admin1),
            country: present(result.country) ?? countryCode.flatMap { present(regionNames.name(forRegionCode: $0)) } ?? countryCode ?? "",
            countryCode: countryCode,
            latitude: result.latitude,
            longitude: result.longitude,
            timeZoneIdentifier: present(result.timezone)
        )
    }

    private func present(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else { return nil }
        return trimmed
    }
}
