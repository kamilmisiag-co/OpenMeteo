//
//  Delaying.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public protocol Delaying: Sendable {
    func delay(for duration: Duration) async throws
}
