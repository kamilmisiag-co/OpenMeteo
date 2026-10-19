//
//  LocaleLanguageCodeProvider.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation

public protocol LanguageCodeProviding: Sendable {
    func languageCode() -> String
}

public struct LocaleLanguageCodeProvider: LanguageCodeProviding {
    private let locale: Locale
    private let fallbackLanguageCode: String

    public init(locale: Locale, fallbackLanguageCode: String) {
        self.locale = locale
        self.fallbackLanguageCode = fallbackLanguageCode
    }

    public func languageCode() -> String {
        guard let code = locale.language.languageCode,
              code.isISOLanguage,
              ![Locale.LanguageCode.unidentified, .unavailable, .uncoded, .multiple].contains(code) else { return fallbackLanguageCode }
        return code.identifier.lowercased()
    }
}
