//
//  StringProtocol+ASCIIDigits.swift
//  Utils
//
//  Created by Kamil Misiag on 18/10/2026.
//

extension StringProtocol {
    public var isASCIIDigits: Bool {
        !isEmpty && unicodeScalars.allSatisfy { ("0"..."9").contains($0) }
    }
}
