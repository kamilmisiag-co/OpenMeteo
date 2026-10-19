//
//  ReportingRecordStoreTests.swift
//  StorageTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic
import LogicMocks
import Storage
import Synchronization
import Testing
import Utils
import UtilsMocks

@Suite("Reporting record store")
struct ReportingRecordStoreTests {
    private enum StoreError: Error, Hashable {
        case unreadable
        case unwritable
    }

    private enum CodingFailure: Error, Hashable {
        case unencodable
    }

    private struct Sample: Codable, Hashable {
        let cityName: String
        let dayCount: Int
    }

    private struct Unencodable: Encodable {
        func encode(to encoder: any Encoder) throws {
            throw CodingFailure.unencodable
        }
    }

    private final class InMemoryDataStore: DataStoring {
        private let entries: Mutex<[String: Data]>
        private let readError: StoreError?
        private let writeError: StoreError?
        private let reads = Mutex<[String]>([])
        private let writes = Mutex<[String]>([])

        init(entries: [String: Data] = [:], readError: StoreError? = nil, writeError: StoreError? = nil) {
            self.entries = Mutex(entries)
            self.readError = readError
            self.writeError = writeError
        }

        var storedEntries: [String: Data] {
            entries.withLock { $0 }
        }

        var readKeys: [String] {
            reads.withLock { $0 }
        }

        var writtenKeys: [String] {
            writes.withLock { $0 }
        }

        func data(forKey key: String) throws -> Data? {
            reads.withLock { $0.append(key) }
            if let readError {
                throw readError
            }
            return entries.withLock { $0[key] }
        }

        func write(_ data: Data, forKey key: String) throws {
            writes.withLock { $0.append(key) }
            if let writeError {
                throw writeError
            }
            entries.withLock { $0[key] = data }
        }
    }

    private static let weatherKey = "weather-2267057"
    private static let citiesKey = "recent-cities"

    private static func recordStore(
        on store: InMemoryDataStore,
        reporter: RecordingReporter,
        encoder: any DataEncoding = JSONEncoder(),
        decoder: any DataDecoding = JSONDecoder()
    ) -> ReportingRecordStore {
        ReportingRecordStore(store: store, encoder: encoder, decoder: decoder, reporter: reporter)
    }

    @Test("Saved records are written under their key and read back without reports")
    func roundTrip() throws {
        let store = InMemoryDataStore()
        let reporter = RecordingReporter()
        let records = Self.recordStore(on: store, reporter: reporter)
        let snapshot = Fixtures.snapshot(for: SampleCities.lisbon)
        let cities = [SampleCities.bergen, SampleCities.zakopane]

        records.save(snapshot, forKey: Self.weatherKey)
        records.save(cities, forKey: Self.citiesKey)

        #expect(records.record(WeatherSnapshot.self, forKey: Self.weatherKey) == snapshot)
        #expect(records.record([City].self, forKey: Self.citiesKey) == cities)
        #expect(store.writtenKeys == [Self.weatherKey, Self.citiesKey])
        #expect(store.readKeys == [Self.weatherKey, Self.citiesKey])
        #expect(Set(store.storedEntries.keys) == [Self.weatherKey, Self.citiesKey])
        #expect(reporter.reports.isEmpty)
    }

    @Test("The injected encoder produces the bytes handed to the store")
    func usesInjectedEncoder() throws {
        let store = InMemoryDataStore()
        let reporter = RecordingReporter()
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = .sortedKeys

        Self.recordStore(on: store, reporter: reporter, encoder: encoder).save(Sample(cityName: "Lisbon", dayCount: 7), forKey: Self.weatherKey)

        let stored = try #require(store.storedEntries[Self.weatherKey])
        #expect(String(decoding: stored, as: UTF8.self) == #"{"city_name":"Lisbon","day_count":7}"#)
        #expect(reporter.reports.isEmpty)
    }

    @Test("The injected decoder turns the stored bytes into the record")
    func usesInjectedDecoder() {
        let store = InMemoryDataStore(entries: [Self.weatherKey: Data(#"{"city_name":"Bergen","day_count":3}"#.utf8)])
        let reporter = RecordingReporter()
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let record = Self.recordStore(on: store, reporter: reporter, decoder: decoder)
            .record(Sample.self, forKey: Self.weatherKey)

        #expect(record == Sample(cityName: "Bergen", dayCount: 3))
        #expect(reporter.reports.isEmpty)
    }

    @Test("A missing record gives nil without a report")
    func missingRecord() {
        let store = InMemoryDataStore()
        let reporter = RecordingReporter()

        #expect(Self.recordStore(on: store, reporter: reporter).record(WeatherSnapshot.self, forKey: Self.weatherKey) == nil)
        #expect(store.readKeys == [Self.weatherKey])
        #expect(reporter.reports.isEmpty)
    }

    @Test("A store read error gives nil and is reported as a read failure for the key")
    func readError() {
        let stored = Data(#"{"cityName":"Bergen","dayCount":3}"#.utf8)
        let store = InMemoryDataStore(entries: [Self.weatherKey: stored], readError: .unreadable)
        let reporter = RecordingReporter()

        #expect(Self.recordStore(on: store, reporter: reporter).record(Sample.self, forKey: Self.weatherKey) == nil)
        #expect(reporter.operations == [StorageOperation(kind: .read, key: Self.weatherKey)])
        #expect((reporter.reports.first?.error as? StoreError) == .unreadable)
    }

    @Test("Data that can't be decoded gives nil and is reported as a decode failure for the key")
    func corruptData() {
        let store = InMemoryDataStore(entries: [Self.weatherKey: Data("not json".utf8)])
        let reporter = RecordingReporter()

        #expect(Self.recordStore(on: store, reporter: reporter).record(WeatherSnapshot.self, forKey: Self.weatherKey) == nil)
        #expect(reporter.operations == [StorageOperation(kind: .decode, key: Self.weatherKey)])
        #expect(reporter.reports.first?.error is DecodingError)
    }

    @Test("The injected decoder's error is the one reported")
    func decoderErrorReported() {
        let store = InMemoryDataStore(entries: [Self.citiesKey: Data("[]".utf8)])
        let reporter = RecordingReporter()

        #expect(Self.recordStore(on: store, reporter: reporter, decoder: FailingDataDecoder()).record([City].self, forKey: Self.citiesKey) == nil)
        #expect(reporter.operations == [StorageOperation(kind: .decode, key: Self.citiesKey)])
        #expect((reporter.reports.first?.error as? UnrelatedError) == .failed)
    }

    @Test("An encoding failure is reported for the key and leaves the stored record untouched")
    func encodingFailure() {
        let existing = Data(#"{"city_name":"Bergen","day_count":3}"#.utf8)
        let store = InMemoryDataStore(entries: [Self.weatherKey: existing])
        let reporter = RecordingReporter()

        Self.recordStore(on: store, reporter: reporter).save(Unencodable(), forKey: Self.weatherKey)

        #expect(reporter.operations == [StorageOperation(kind: .encode, key: Self.weatherKey)])
        #expect((reporter.reports.first?.error as? CodingFailure) == .unencodable)
        #expect(store.writtenKeys.isEmpty)
        #expect(store.storedEntries == [Self.weatherKey: existing])
    }

    @Test("A store write error is reported as a write failure for the key")
    func writeError() {
        let store = InMemoryDataStore(writeError: .unwritable)
        let reporter = RecordingReporter()

        Self.recordStore(on: store, reporter: reporter).save([SampleCities.lisbon], forKey: Self.citiesKey)

        #expect(store.writtenKeys == [Self.citiesKey])
        #expect(reporter.operations == [StorageOperation(kind: .write, key: Self.citiesKey)])
        #expect((reporter.reports.first?.error as? StoreError) == .unwritable)
    }
}
