//
//  LocaleRegionNameProvider.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation

public protocol RegionNameProviding: Sendable {
    func name(forRegionCode code: String) -> String?
}

public struct LocaleRegionNameProvider: RegionNameProviding {
    private let locale: Locale

    public init(locale: Locale) {
        self.locale = locale
    }

    public func name(forRegionCode code: String) -> String? {
        locale.localizedString(forRegionCode: code)
    }
}
