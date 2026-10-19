//
//  String+NonBlank.swift
//  Utils
//
//  Created by Kamil Misiag on 19/10/2026.
//

import Foundation

extension String {
    public var nonBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
