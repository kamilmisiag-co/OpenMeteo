//
//  ForecastRequestMaking.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic

public protocol ForecastRequestMaking: Sendable {
    func request(for city: City, upcomingDays dayCount: Int) -> ForecastEndpoint
}
