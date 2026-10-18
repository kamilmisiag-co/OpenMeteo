//
//  StorageStandard.swift
//  Storage
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation

public enum StorageStandard {
    public static let weatherCacheDirectoryName = "WeatherCache"
    public static let recentCitiesDirectoryName = "RecentCities"
    public static let weatherKeyPrefix = "weather-"
    public static let recentCitiesKey = "recent-cities"
    public static let fileExtension = "json"
    public static let allowedKeyCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_")
}
