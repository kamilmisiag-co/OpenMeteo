//
//  DateProviding.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Foundation

public protocol DateProviding: Sendable {
    func now() -> Date
}
