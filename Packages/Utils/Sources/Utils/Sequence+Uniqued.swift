//
//  Sequence+Uniqued.swift
//  Utils
//
//  Created by Kamil Misiag on 17/10/2026.
//

extension Sequence {
    public func uniqued<Key: Hashable>(by key: (Element) throws -> Key) rethrows -> [Element] {
        var seenKeys = Set<Key>()
        return try filter { seenKeys.insert(try key($0)).inserted }
    }
}
