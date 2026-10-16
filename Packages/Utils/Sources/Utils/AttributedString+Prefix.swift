//
//  AttributedString+Prefix.swift
//  Utils
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation

extension AttributedString {
    public func applying(_ attributes: AttributeContainer, toPrefixMatching prefix: String) -> AttributedString {
        var result = self
        guard !prefix.isEmpty,
              let range = result.range(of: prefix, options: [.anchored, .caseInsensitive, .diacriticInsensitive]) else { return result }
        result[range].mergeAttributes(attributes)
        return result
    }
}
