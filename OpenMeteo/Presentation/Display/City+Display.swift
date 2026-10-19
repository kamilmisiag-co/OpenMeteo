//
//  City+Display.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic
import Utils

extension City {
    var subtitle: String {
        let region = region?.trimmingCharacters(in: .whitespaces) ?? ""
        let country = country.trimmingCharacters(in: .whitespaces)
        guard !region.isEmpty else { return country }
        guard !country.isEmpty else { return region }
        return String(localized: .citySubtitle(region, country))
    }

    var flag: String? {
        countryCode?.regionalIndicatorFlag
    }
}
