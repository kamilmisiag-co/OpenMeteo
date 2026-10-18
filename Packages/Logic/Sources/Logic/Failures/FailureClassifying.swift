//
//  FailureClassifying.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public protocol FailureClassifying: Sendable {
    func failure(for error: any Error) -> ServiceFailure
}
