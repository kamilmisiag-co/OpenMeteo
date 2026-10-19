//
//  StubQueryNormalizer.swift
//  LogicMocks
//
//  Created by Kamil Misiag on 19/10/2026.
//

import Logic

public final class StubQueryNormalizer: SearchQueryNormalizing {
    public typealias Handler = @Sendable (String) -> String?

    private let handler: Handler

    public init(handler: @escaping Handler) {
        self.handler = handler
    }

    public func normalizedQuery(from rawQuery: String) -> String? {
        handler(rawQuery)
    }
}
