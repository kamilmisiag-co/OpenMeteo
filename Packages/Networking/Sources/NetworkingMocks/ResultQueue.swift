//
//  ResultQueue.swift
//  NetworkingMocks
//
//  Created by Kamil Misiag on 16/10/2026.
//

struct ResultQueue<Value: Sendable>: Sendable {
    private var results: [Result<Value, any Error>]
    private let repeatsLast: Bool

    init(_ results: [Result<Value, any Error>], repeatsLast: Bool) {
        self.results = results
        self.repeatsLast = repeatsLast
    }

    mutating func next() -> Result<Value, any Error>? {
        guard let first = results.first else { return nil }
        if results.count > 1 || !repeatsLast {
            results.removeFirst()
        }
        return first
    }
}
