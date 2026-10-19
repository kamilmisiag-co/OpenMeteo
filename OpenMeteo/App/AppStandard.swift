//
//  AppStandard.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation

enum AppStandard {
    static let searchProgressDelay = Duration.milliseconds(300)
    static let precipitationLabelThreshold = 0.3
    static let maximumReasonCauses = 2
    static let openMeteoURL = URL(string: "https://open-meteo.com")!
    static let licenceURL = URL(string: "https://creativecommons.org/licenses/by/4.0/")!
    static let geoNamesURL = URL(string: "https://www.geonames.org")!
    static let networkLogCategory = "network"
    static let storageLogCategory = "storage"
    static let sampleDataArgument = "--sample-data"
}
