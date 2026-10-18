//
//  StorageFailureReporting.swift
//  Storage
//
//  Created by Kamil Misiag on 18/10/2026.
//

public protocol StorageFailureReporting: Sendable {
    func report(_ error: any Error, during operation: StorageOperation)
}
