//
//  LocaleRegionNameProviderTests.swift
//  OpenMeteoAPITests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation
import OpenMeteoAPI
import Testing

@Suite("Locale region name provider")
struct LocaleRegionNameProviderTests {
    @Test(
        "The region name is the injected locale's localized name for the code",
        arguments: [("en_US", "PR"), ("pl_PL", "PR"), ("en_US", "PT"), ("pl_PL", "PT"), ("de_DE", "US"), ("pt_BR", "CV")]
    )
    func localizedName(localeIdentifier: String, code: String) throws {
        let locale = Locale(identifier: localeIdentifier)
        let expected = try #require(locale.localizedString(forRegionCode: code))
        #expect(LocaleRegionNameProvider(locale: locale).name(forRegionCode: code) == expected)
    }

    @Test("Two injected locales give two different names for the same code")
    func localeInjection() throws {
        let english = Locale(identifier: "en_US")
        let polish = Locale(identifier: "pl_PL")
        let englishName = try #require(english.localizedString(forRegionCode: "PR"))
        let polishName = try #require(polish.localizedString(forRegionCode: "PR"))
        try #require(englishName != polishName)
        #expect(LocaleRegionNameProvider(locale: english).name(forRegionCode: "PR") == englishName)
        #expect(LocaleRegionNameProvider(locale: polish).name(forRegionCode: "PR") == polishName)
    }

    @Test("A code the locale does not know has no name")
    func unknownCode() throws {
        let locale = Locale(identifier: "en_US")
        try #require(locale.localizedString(forRegionCode: "XX") == nil)
        #expect(LocaleRegionNameProvider(locale: locale).name(forRegionCode: "XX") == nil)
    }
}
