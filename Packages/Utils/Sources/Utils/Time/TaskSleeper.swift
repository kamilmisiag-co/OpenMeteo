//
//  TaskSleeper.swift
//  Utils
//
//  Created by Kamil Misiag on 18/10/2026.
//

public protocol Sleeping: Sendable {
    func sleep(for duration: Duration) async throws
}

public struct TaskSleeper: Sleeping {
    public init() {}

    public func sleep(for duration: Duration) async throws {
        try await Task.sleep(for: duration)
    }
}
