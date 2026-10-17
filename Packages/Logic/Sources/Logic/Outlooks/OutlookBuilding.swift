//
//  OutlookBuilding.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public protocol OutlookBuilding: Sendable {
    func outlooks(for days: [DailyWeather]) -> [ActivityOutlook]
}
