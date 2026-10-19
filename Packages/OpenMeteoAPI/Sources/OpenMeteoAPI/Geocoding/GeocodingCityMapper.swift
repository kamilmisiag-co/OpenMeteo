//
//  GeocodingCityMapper.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic
import Utils

public protocol CityMapping: Sendable {
    func city(from result: GeocodingResultDTO) -> City?
}

public struct GeocodingCityMapper: CityMapping {
    private let regionNames: any RegionNameProviding

    public init(regionNames: any RegionNameProviding) {
        self.regionNames = regionNames
    }

    public func city(from result: GeocodingResultDTO) -> City? {
        guard let name = result.name.nonBlank else { return nil }
        let countryCode = result.countryCode?.nonBlank?.uppercased()
        return City(
            id: result.id,
            name: name,
            region: result.admin1?.nonBlank,
            country: result.country?.nonBlank ?? countryCode.flatMap { regionNames.name(forRegionCode: $0)?.nonBlank } ?? countryCode ?? "",
            countryCode: countryCode,
            latitude: result.latitude,
            longitude: result.longitude,
            timeZoneIdentifier: result.timezone?.nonBlank
        )
    }
}
