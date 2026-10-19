//
//  AppStandard.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation

enum AppStandard {
    static let searchProgressDelay = Duration.milliseconds(300)
    static let openMeteoURLString = "https://open-meteo.com"
    static let licenceURLString = "https://creativecommons.org/licenses/by/4.0/"
    static let geoNamesURLString = "https://www.geonames.org"
    static let networkLogCategory = "network"
    static let storageLogCategory = "storage"
    static let fallbackLogSubsystem = "com.km.OpenMeteo"
    static let launchLogCategory = "launch"
}
