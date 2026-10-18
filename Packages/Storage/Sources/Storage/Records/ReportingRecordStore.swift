//
//  ReportingRecordStore.swift
//  Storage
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation

public struct ReportingRecordStore: RecordStoring {
    private let store: any DataStoring
    private let encoder: any ValueEncoding
    private let decoder: any ValueDecoding
    private let reporter: any StorageFailureReporting

    public init(
        store: any DataStoring,
        encoder: any ValueEncoding,
        decoder: any ValueDecoding,
        reporter: any StorageFailureReporting
    ) {
        self.store = store
        self.encoder = encoder
        self.decoder = decoder
        self.reporter = reporter
    }

    public func record<Record: Decodable>(_ type: Record.Type, forKey key: String) -> Record? {
        let data: Data?
        do {
            data = try store.data(forKey: key)
        } catch {
            reporter.report(error, during: StorageOperation(kind: .read, key: key))
            return nil
        }
        guard let data else { return nil }
        do {
            return try decoder.decode(type, from: data)
        } catch {
            reporter.report(error, during: StorageOperation(kind: .decode, key: key))
            return nil
        }
    }

    public func save<Record: Encodable>(_ record: Record, forKey key: String) {
        let data: Data
        do {
            data = try encoder.encode(record)
        } catch {
            reporter.report(error, during: StorageOperation(kind: .encode, key: key))
            return
        }
        do {
            try store.write(data, forKey: key)
        } catch {
            reporter.report(error, during: StorageOperation(kind: .write, key: key))
        }
    }
}
