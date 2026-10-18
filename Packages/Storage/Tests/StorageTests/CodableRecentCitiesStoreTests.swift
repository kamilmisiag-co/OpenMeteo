//
//  CodableRecentCitiesStoreTests.swift
//  StorageTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic
import Storage
import Testing

@Suite("Codable recent cities store")
struct CodableRecentCitiesStoreTests {
    private typealias Records = RecordingRecordStore<[City]>

    @Test("Loading asks the record store for a city list under the injected key")
    func loadUsesInjectedKey() {
        let records = Records(stored: [Fixtures.bergen, Fixtures.lisbon])
        #expect(CodableRecentCitiesStore(records: records, key: "custom_key").load() == [Fixtures.bergen, Fixtures.lisbon])
        #expect(records.reads == [RecordRead([City].self, key: "custom_key")])
        #expect(records.saves.isEmpty)
    }

    @Test("Loading gives an empty list when the record store has no record")
    func loadWithoutRecord() {
        let records = Records(stored: nil)
        #expect(CodableRecentCitiesStore(records: records, key: "custom_key").load().isEmpty)
        #expect(records.reads == [RecordRead([City].self, key: "custom_key")])
    }

    @Test("Saving passes the cities to the record store under the injected key", arguments: [
        [Fixtures.zakopane, Fixtures.lisbon],
        [],
    ])
    func savePassesThrough(cities: [City]) {
        let records = Records(stored: nil)
        CodableRecentCitiesStore(records: records, key: "custom_key").save(cities)
        #expect(records.saves == [Records.Save([City].self, key: "custom_key", record: cities)])
        #expect(records.reads.isEmpty)
    }

    @Test("Saved cities load back in the same order from a fresh store over the same directory")
    func orderPreserved() {
        let root = TestSupport.temporaryDirectory()
        defer { TestSupport.removeDirectory(root) }
        let reporter = RecordingReporter()
        let cities = [Fixtures.zakopane, Fixtures.lisbon, Fixtures.bergen]

        Self.makeStore(root: root, reporter: reporter).save(cities)

        #expect(Self.makeStore(root: root, reporter: reporter).load() == cities)
        #expect(TestSupport.fileExists(Self.file(in: root)))
        #expect(reporter.operations.isEmpty)
    }

    @Test("An empty list round trips and replaces an earlier list")
    func emptyListRoundTrips() {
        let root = TestSupport.temporaryDirectory()
        defer { TestSupport.removeDirectory(root) }
        let reporter = RecordingReporter()
        let store = Self.makeStore(root: root, reporter: reporter)

        store.save([Fixtures.lisbon, Fixtures.bergen])
        store.save([])

        #expect(Self.makeStore(root: root, reporter: reporter).load().isEmpty)
        #expect(TestSupport.fileExists(Self.file(in: root)))
        #expect(reporter.operations.isEmpty)
    }

    @Test("Nothing saved yet loads an empty list without reporting a failure")
    func nothingSaved() {
        let root = TestSupport.temporaryDirectory()
        defer { TestSupport.removeDirectory(root) }
        let reporter = RecordingReporter()
        #expect(Self.makeStore(root: root, reporter: reporter).load().isEmpty)
        #expect(reporter.operations.isEmpty)
    }

    @Test("A corrupt file loads an empty list and is reported as a decode failure", arguments: [
        "",
        "not json",
        "{}",
        "[{\"id\":1}]",
    ])
    func corruptFile(payload: String) throws {
        let root = TestSupport.temporaryDirectory()
        defer { TestSupport.removeDirectory(root) }
        let reporter = RecordingReporter()
        try TestSupport.write(payload, to: Self.file(in: root))

        #expect(Self.makeStore(root: root, reporter: reporter).load().isEmpty)
        #expect(reporter.operations == [StorageOperation(kind: .decode, key: "recent-cities")])
    }

    @Test("Saving over a corrupt file replaces it")
    func saveRepairsCorruptFile() throws {
        let root = TestSupport.temporaryDirectory()
        defer { TestSupport.removeDirectory(root) }
        let reporter = RecordingReporter()
        let store = Self.makeStore(root: root, reporter: reporter)
        try TestSupport.write("not json", to: Self.file(in: root))

        store.save([Fixtures.bergen])

        #expect(store.load() == [Fixtures.bergen])
        #expect(reporter.operations.isEmpty)
    }

    private static func directory(in root: URL) -> URL {
        TestSupport.directory(named: StorageStandard.recentCitiesDirectoryName, in: root)
    }

    private static func file(in root: URL) -> URL {
        TestSupport.fileURL(named: "recent-cities.json", in: directory(in: root))
    }

    private static func makeStore(root: URL, reporter: RecordingReporter) -> CodableRecentCitiesStore {
        CodableRecentCitiesStore(
            records: TestSupport.recordStore(in: directory(in: root), reporter: reporter),
            key: StorageStandard.recentCitiesKey
        )
    }
}
