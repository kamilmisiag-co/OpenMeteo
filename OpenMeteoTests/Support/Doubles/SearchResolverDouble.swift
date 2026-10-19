//
//  SearchResolverDouble.swift
//  OpenMeteoTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic
import Synchronization

final class SearchResolverDouble: SearchStateResolving {
    struct Request: Hashable, Sendable {
        let query: String
        let debounced: Bool
    }

    private let immediate: @Sendable (String, CitySearchState) -> CitySearchState?
    private let resolution: @Sendable (Request) async -> CitySearchState?
    private let recorded = Mutex<[Request]>([])

    init(
        immediate: @escaping @Sendable (String, CitySearchState) -> CitySearchState?,
        resolution: @escaping @Sendable (Request) async -> CitySearchState?
    ) {
        self.immediate = immediate
        self.resolution = resolution
    }

    var requests: [Request] {
        recorded.withLock { $0 }
    }

    func immediateState(for rawQuery: String, current: CitySearchState) -> CitySearchState? {
        immediate(rawQuery, current)
    }

    func resolvedState(for rawQuery: String, debounced: Bool) async -> CitySearchState? {
        let request = Request(query: rawQuery, debounced: debounced)
        recorded.withLock { $0.append(request) }
        return await resolution(request)
    }
}
