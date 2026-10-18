//
//  TaskDelayer.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public struct TaskDelayer: Delaying {
    public init() {}

    public func delay(for duration: Duration) async throws {
        try await Task.sleep(for: duration)
    }
}
