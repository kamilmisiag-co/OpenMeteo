//
//  CitySearchQueryNormalizer.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public struct CitySearchQueryNormalizer: SearchQueryNormalizing {
    private static let invisibleScalars: Set<Unicode.Scalar> = ["\u{200B}", "\u{FEFF}"]

    private let minimumLength: Int
    private let separators: Set<Character>

    public init(minimumLength: Int, separators: Set<Character>) {
        self.minimumLength = minimumLength
        self.separators = separators
    }

    public func normalizedQuery(from rawQuery: String) -> String? {
        let visible = String(String.UnicodeScalarView(rawQuery.unicodeScalars.filter(Self.isVisible)))
        let query = visible
            .prefix { !separators.contains($0) }
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
        guard !query.isEmpty, query.count >= minimumLength else { return nil }
        return query
    }

    private static func isVisible(_ scalar: Unicode.Scalar) -> Bool {
        !scalar.properties.isBidiControl && !invisibleScalars.contains(scalar)
    }
}
