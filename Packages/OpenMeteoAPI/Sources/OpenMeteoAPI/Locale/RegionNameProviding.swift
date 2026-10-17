//
//  RegionNameProviding.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

public protocol RegionNameProviding: Sendable {
    func name(forRegionCode code: String) -> String?
}
