//
//  String+Utils.swift
//  Utils
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation

extension String {
    public var regionalIndicatorFlag: String? {
        let code = uppercased()
        guard code.count == 2 else { return nil }
        var flag = ""
        for scalar in code.unicodeScalars {
            guard (65...90).contains(scalar.value),
                  let indicator = Unicode.Scalar(127_397 + scalar.value) else { return nil }
            flag.unicodeScalars.append(indicator)
        }
        return flag
    }

    public func leadingComponent(separatedBy separator: Character) -> String? {
        split(separator: separator, maxSplits: 1)
            .first
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }

    public func hasPrefixIgnoringCaseAndDiacritics(_ prefix: String) -> Bool {
        range(of: prefix, options: [.anchored, .caseInsensitive, .diacriticInsensitive]) != nil
    }
}
