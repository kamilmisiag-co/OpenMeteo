//
//  SystemDateProviderTests.swift
//  UtilsTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Testing
import Utils

@Suite("System date provider")
struct SystemDateProviderTests {
    private let provider = SystemDateProvider()

    @Test("The current date lies between two readings of the system clock")
    func readsSystemClock() {
        let before = Date()
        let now = provider.now()
        let after = Date()
        #expect(before <= now)
        #expect(now <= after)
    }
}
