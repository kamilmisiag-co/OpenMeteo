//
//  FileSystemAccessing.swift
//  Storage
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation

public protocol FileSystemAccessing: Sendable {
    func contents(at url: URL) throws -> Data?
    func write(_ data: Data, to url: URL) throws
    func createDirectory(at url: URL) throws
}
