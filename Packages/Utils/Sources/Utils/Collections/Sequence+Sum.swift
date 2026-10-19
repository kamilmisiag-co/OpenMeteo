//
//  Sequence+Sum.swift
//  Utils
//
//  Created by Kamil Misiag on 19/10/2026.
//

extension Sequence {
    public func sum<Value: AdditiveArithmetic>(of value: (Element) throws -> Value) rethrows -> Value {
        try reduce(.zero) { $0 + (try value($1)) }
    }
}

extension Sequence where Element: AdditiveArithmetic {
    public func sum() -> Element {
        reduce(.zero, +)
    }
}
