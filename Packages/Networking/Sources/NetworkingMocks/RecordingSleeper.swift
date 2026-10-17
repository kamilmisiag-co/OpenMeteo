//
//  RecordingSleeper.swift
//  NetworkingMocks
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Networking

public actor RecordingSleeper: Sleeping {
    public private(set) var durations: [Duration] = []

    public init() {}

    public func sleep(for duration: Duration) async throws {
        durations.append(duration)
        try Task.checkCancellation()
    }
}
