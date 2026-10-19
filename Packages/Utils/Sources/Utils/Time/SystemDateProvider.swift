//
//  SystemDateProvider.swift
//  Utils
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation

public protocol DateProviding: Sendable {
    func now() -> Date
}

public struct SystemDateProvider: DateProviding {
    public init() {}

    public func now() -> Date {
        Date()
    }
}
