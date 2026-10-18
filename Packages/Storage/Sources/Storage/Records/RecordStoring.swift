//
//  RecordStoring.swift
//  Storage
//
//  Created by Kamil Misiag on 18/10/2026.
//

public protocol RecordStoring: Sendable {
    func record<Record: Decodable>(_ type: Record.Type, forKey key: String) -> Record?
    func save<Record: Encodable>(_ record: Record, forKey key: String)
}
