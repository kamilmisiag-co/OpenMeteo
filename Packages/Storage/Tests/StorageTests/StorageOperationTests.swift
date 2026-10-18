//
//  StorageOperationTests.swift
//  StorageTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Storage
import Testing

@Suite("Storage operation")
struct StorageOperationTests {
    @Test("Each operation kind has a stable name for the log", arguments: StorageOperation.Kind.allCases)
    func kindName(kind: StorageOperation.Kind) {
        #expect(kind.rawValue == expectedName(of: kind))
    }

    @Test("An operation keeps the kind and key it was made with", arguments: StorageOperation.Kind.allCases)
    func keepsKindAndKey(kind: StorageOperation.Kind) {
        let operation = StorageOperation(kind: kind, key: "weather-2267057")
        #expect(operation.kind == kind)
        #expect(operation.key == "weather-2267057")
    }

    @Test(
        "Operations are equal exactly when both kind and key match",
        arguments: StorageOperation.Kind.allCases, StorageOperation.Kind.allCases
    )
    func equality(kind: StorageOperation.Kind, otherKind: StorageOperation.Kind) {
        let operation = StorageOperation(kind: kind, key: "weather-2267057")
        let sameKey = StorageOperation(kind: otherKind, key: "weather-2267057")
        let otherKey = StorageOperation(kind: otherKind, key: "recent-cities")

        #expect((operation == sameKey) == (kind == otherKind))
        #expect(operation != otherKey)
        #expect(Set([operation, sameKey, otherKey]).count == (kind == otherKind ? 2 : 3))
    }

    private func expectedName(of kind: StorageOperation.Kind) -> String {
        switch kind {
        case .read: "read"
        case .write: "write"
        case .encode: "encode"
        case .decode: "decode"
        }
    }
}
