//
//  String+PrefixMatching.swift
//  Utils
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation

extension String {
    public func leadingComponent(separatedBy separator: Character) -> String? {
        split(separator: separator, maxSplits: 1)
            .first
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }

    public func hasPrefixIgnoringCaseAndDiacritics(_ prefix: String) -> Bool {
        range(of: prefix, options: TextMatching.prefixOptions) != nil
    }
}
