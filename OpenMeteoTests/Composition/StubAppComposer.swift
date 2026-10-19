//
//  StubAppComposer.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

@testable import OpenMeteo

@MainActor
final class StubAppComposer: AppComposing {
    private let result: Result<AppSession, AppCompositionError>
    private(set) var callCount = 0

    init(result: Result<AppSession, AppCompositionError>) {
        self.result = result
    }

    func makeSession() throws -> AppSession {
        callCount += 1
        return try result.get()
    }
}
