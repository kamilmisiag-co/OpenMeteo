//
//  Sleeping.swift
//  Utils
//
//  Created by Kamil Misiag on 18/10/2026.
//

public protocol Sleeping: Sendable {
    func sleep(for duration: Duration) async throws
}
