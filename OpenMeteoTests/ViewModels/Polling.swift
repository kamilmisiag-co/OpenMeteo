//
//  Polling.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

@MainActor
enum Polling {
    @discardableResult
    static func until(timeout: Duration = .seconds(2), _ condition: () -> Bool) async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        while !condition() {
            guard clock.now < deadline else { return false }
            try? await Task.sleep(for: .milliseconds(1))
        }
        return true
    }
}
