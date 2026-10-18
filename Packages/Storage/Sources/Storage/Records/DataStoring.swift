//
//  DataStoring.swift
//  Storage
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation

public protocol DataStoring: Sendable {
    func data(forKey key: String) throws -> Data?
    func write(_ data: Data, forKey key: String) throws
}
