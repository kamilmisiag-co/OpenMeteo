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
        guard let region = region?.nonBlank else { return country.nonBlank ?? "" }
        guard let country = country.nonBlank else { return region }
        return String(localized: .citySubtitle(region, country))
    }

    var flag: String? {
        countryCode?.regionalIndicatorFlag
    }
}
