//
//  BinaryFloatingPoint+Rounding.swift
//  Utils
//
//  Created by Kamil Misiag on 18/10/2026.
//

extension BinaryFloatingPoint {
    public func roundedInt() -> Int? {
        Int(exactly: rounded())
    }
}
