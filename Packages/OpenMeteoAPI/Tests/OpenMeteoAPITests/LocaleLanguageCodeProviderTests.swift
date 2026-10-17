//
//  LocaleLanguageCodeProviderTests.swift
//  OpenMeteoAPITests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import OpenMeteoAPI
import Testing

@Suite("Locale language code provider")
struct LocaleLanguageCodeProviderTests {
    private static let fallbackLanguageCode = "pl"

    @Test(
        "The language code is the injected locale's lowercased language",
        arguments: [
            ("en_US", "en"), ("pt_BR", "pt"), ("zh-Hant-TW", "zh"), ("de_CH", "de"), ("sr-Latn-RS", "sr"),
            ("EN_US", "en"), ("PT_br", "pt"), ("EN", "en"),
        ]
    )
    func languageCode(localeIdentifier: String, expected: String) {
        let provider = LocaleLanguageCodeProvider(locale: Locale(identifier: localeIdentifier), fallbackLanguageCode: Self.fallbackLanguageCode)
        #expect(provider.languageCode() == expected)
    }

    @Test("A locale without a language uses the injected fallback", arguments: ["pl", "de"])
    func fallback(fallbackLanguageCode: String) {
        let locale = Locale(identifier: "")
        let provider = LocaleLanguageCodeProvider(locale: locale, fallbackLanguageCode: fallbackLanguageCode)
        #expect(locale.language.languageCode == nil)
        #expect(provider.languageCode() == fallbackLanguageCode)
    }

    @Test("A reserved or non-ISO language code uses the injected fallback", arguments: ["und", "root", "mul", "mis", "zxx", "qaa"])
    func reservedCode(localeIdentifier: String) {
        let provider = LocaleLanguageCodeProvider(locale: Locale(identifier: localeIdentifier), fallbackLanguageCode: Self.fallbackLanguageCode)
        #expect(provider.languageCode() == Self.fallbackLanguageCode)
    }
}
