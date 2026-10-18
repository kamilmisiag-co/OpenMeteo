//
//  MockSearchStateResolver.swift
//  LogicMocks
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic
import Synchronization

public final class MockSearchStateResolver: SearchStateResolving {
    public struct Resolution: Hashable, Sendable {
        public let rawQuery: String
        public let debounced: Bool

        public init(rawQuery: String, debounced: Bool) {
            self.rawQuery = rawQuery
            self.debounced = debounced
        }
    }

    public typealias ImmediateHandler = @Sendable (String, CitySearchState) -> CitySearchState?
    public typealias ResolvedHandler = @Sendable (String, Bool) async -> CitySearchState?

    private let immediate: ImmediateHandler
    private let resolved: ResolvedHandler
    private let recorded = Mutex<[Resolution]>([])

    public init(immediate: @escaping ImmediateHandler, resolved: @escaping ResolvedHandler) {
        self.immediate = immediate
        self.resolved = resolved
    }

    public var resolutions: [Resolution] {
        recorded.withLock { $0 }
    }

    public func immediateState(for rawQuery: String, current: CitySearchState) -> CitySearchState? {
        immediate(rawQuery, current)
    }

    public func resolvedState(for rawQuery: String, debounced: Bool) async -> CitySearchState? {
        recorded.withLock { $0.append(Resolution(rawQuery: rawQuery, debounced: debounced)) }
        return await resolved(rawQuery, debounced)
    }
}
