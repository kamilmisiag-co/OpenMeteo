//
//  SearchFailureClassifying.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public protocol SearchFailureClassifying: Sendable {
    func failure(for error: any Error) -> SearchFailure
}
