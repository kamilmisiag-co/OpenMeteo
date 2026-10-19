//
//  String+PrefixMatching.swift
//  Utils
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation

extension String {
    public func hasPrefixIgnoringCaseAndDiacritics(_ prefix: String) -> Bool {
        range(of: prefix, options: TextMatching.prefixOptions) != nil
    }
}
