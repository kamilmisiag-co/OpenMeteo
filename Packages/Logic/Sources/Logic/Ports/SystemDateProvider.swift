//
//  SystemDateProvider.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation

public struct SystemDateProvider: DateProviding {
    public init() {}

    public func now() -> Date {
        Date()
    }
}
