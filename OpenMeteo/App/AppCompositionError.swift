//
//  AppCompositionError.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

nonisolated enum AppCompositionError: Error, Hashable {
    case invalidBaseURL(host: String)
}
