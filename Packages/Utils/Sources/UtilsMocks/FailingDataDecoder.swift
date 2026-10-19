//
//  FailingDataDecoder.swift
//  UtilsMocks
//
//  Created by Kamil Misiag on 19/10/2026.
//

import Foundation
import Utils

public struct FailingDataDecoder: DataDecoding {
    private let error: any Error

    public init(error: any Error = UnrelatedError.failed) {
        self.error = error
    }

    public func decode<Value: Decodable>(_ type: Value.Type, from data: Data) throws -> Value {
        throw error
    }
}
