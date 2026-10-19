//
//  FloatingPoint+Finite.swift
//  Utils
//
//  Created by Kamil Misiag on 19/10/2026.
//

extension FloatingPoint {
    public var finiteValue: Self? {
        isFinite ? self : nil
    }
}
