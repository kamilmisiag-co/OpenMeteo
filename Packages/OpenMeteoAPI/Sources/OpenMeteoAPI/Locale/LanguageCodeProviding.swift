//
//  LanguageCodeProviding.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

public protocol LanguageCodeProviding: Sendable {
    func languageCode() -> String
}
