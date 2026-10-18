//
//  CodableWeatherCacheTests.swift
//  StorageTests
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic
import Storage
import Testing

@Suite("Codable weather cache")
struct CodableWeatherCacheTests {
    private typealias Records = RecordingRecordStore<WeatherSnapshot>

    @Test("Reading asks the record store for a weather snapshot under the injected key")
    func readUsesInjectedKey() async {
        let records = Records(stored: nil)
        let cache = CodableWeatherCache(records: records, keys: NameCityKeys())
        #expect(await cache.snapshot(for: Fixtures.lisbon) == nil)
        #expect(records.reads == [RecordRead(WeatherSnapshot.self, key: "city:Lisbon")])
        #expect(records.saves.isEmpty)
    }

    @Test("Reading returns the snapshot the record store gives back")
    func readReturnsRecord() async {
        let snapshot = Fixtures.snapshot(for: Fixtures.bergen)
        let records = Records(stored: snapshot)
        #expect(await CodableWeatherCache(records: records, keys: NameCityKeys()).snapshot(for: Fixtures.bergen) == snapshot)
        #expect(records.reads == [RecordRead(WeatherSnapshot.self, key: "city:Bergen")])
    }

    @Test("Storing saves the snapshot under the injected key for the snapshot's city")
    func storeUsesSnapshotCityKey() async {
        let records = Records(stored: nil)
        let snapshot = Fixtures.snapshot(for: Fixtures.zakopane)
        await CodableWeatherCache(records: records, keys: NameCityKeys()).store(snapshot)
        #expect(records.saves == [Records.Save(WeatherSnapshot.self, key: "city:Zakopane", record: snapshot)])
        #expect(records.reads.isEmpty)
    }

    @Test("A stored snapshot reads back exactly from a fresh cache over the same directory")
    func roundTrip() async throws {
        let root = TestSupport.temporaryDirectory()
        defer { TestSupport.removeDirectory(root) }
        let reporter = RecordingReporter()
        let snapshot = Fixtures.snapshot(for: Fixtures.lisbon)
        try #require(snapshot.fetchedAt.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1) != 0)
        try #require(snapshot.days.contains { $0.snowDepthCm == nil })
        try #require(snapshot.days.contains { $0.snowDepthCm != nil })

        await Self.makeCache(root: root, reporter: reporter).store(snapshot)
        let restored = try #require(await Self.makeCache(root: root, reporter: reporter).snapshot(for: Fixtures.lisbon))

        #expect(restored == snapshot)
        #expect(TestSupport.fileExists(Self.file(named: "weather-2267057.json", in: root)))
        #expect(reporter.operations.isEmpty)
    }

    @Test("Each city reads back only its own snapshot")
    func citiesAreIsolated() async {
        let root = TestSupport.temporaryDirectory()
        defer { TestSupport.removeDirectory(root) }
        let reporter = RecordingReporter()
        let cache = Self.makeCache(root: root, reporter: reporter)
        let lisbon = Fixtures.snapshot(for: Fixtures.lisbon)
        let bergen = Fixtures.snapshot(for: Fixtures.bergen, dayCount: 3)

        await cache.store(lisbon)
        await cache.store(bergen)

        #expect(await cache.snapshot(for: Fixtures.lisbon) == lisbon)
        #expect(await cache.snapshot(for: Fixtures.bergen) == bergen)
        #expect(await cache.snapshot(for: Fixtures.zakopane) == nil)
        #expect(reporter.operations.isEmpty)
    }

    @Test("A later store for the same city replaces the earlier snapshot")
    func laterStoreReplaces() async {
        let root = TestSupport.temporaryDirectory()
        defer { TestSupport.removeDirectory(root) }
        let reporter = RecordingReporter()
        let cache = Self.makeCache(root: root, reporter: reporter)
        let earlier = Fixtures.snapshot(for: Fixtures.lisbon)
        let later = Fixtures.snapshot(for: Fixtures.lisbon, dayCount: 3, fetchedAt: Fixtures.referenceNow.addingTimeInterval(3_600.25))

        await cache.store(earlier)
        await cache.store(later)

        #expect(await Self.makeCache(root: root, reporter: reporter).snapshot(for: Fixtures.lisbon) == later)
        #expect(reporter.operations.isEmpty)
    }

    @Test("A city with nothing stored reads as nil without reporting a failure")
    func missingCity() async {
        let root = TestSupport.temporaryDirectory()
        defer { TestSupport.removeDirectory(root) }
        let reporter = RecordingReporter()
        #expect(await Self.makeCache(root: root, reporter: reporter).snapshot(for: Fixtures.lisbon) == nil)
        #expect(reporter.operations.isEmpty)
    }

    @Test("A corrupt file reads as nil and is reported as a decode failure for the city key", arguments: [
        "",
        "not json",
        "[]",
        "{\"fetchedAt\":1}",
    ])
    func corruptFile(payload: String) async throws {
        let root = TestSupport.temporaryDirectory()
        defer { TestSupport.removeDirectory(root) }
        let reporter = RecordingReporter()
        try TestSupport.write(payload, to: Self.file(named: "weather-2267057.json", in: root))

        #expect(await Self.makeCache(root: root, reporter: reporter).snapshot(for: Fixtures.lisbon) == nil)
        #expect(reporter.operations == [StorageOperation(kind: .decode, key: "weather-2267057")])
    }

    @Test("Storing over a corrupt file replaces it")
    func storeRepairsCorruptFile() async throws {
        let root = TestSupport.temporaryDirectory()
        defer { TestSupport.removeDirectory(root) }
        let reporter = RecordingReporter()
        let cache = Self.makeCache(root: root, reporter: reporter)
        let snapshot = Fixtures.snapshot(for: Fixtures.lisbon)
        try TestSupport.write("not json", to: Self.file(named: "weather-2267057.json", in: root))

        await cache.store(snapshot)

        #expect(await cache.snapshot(for: Fixtures.lisbon) == snapshot)
        #expect(reporter.operations.isEmpty)
    }

    private struct NameCityKeys: WeatherCacheKeying {
        func key(for city: City) -> String {
            "city:" + city.name
        }
    }

    private static func directory(in root: URL) -> URL {
        TestSupport.directory(named: StorageStandard.weatherCacheDirectoryName, in: root)
    }

    private static func file(named name: String, in root: URL) -> URL {
        TestSupport.fileURL(named: name, in: directory(in: root))
    }

    private static func makeCache(root: URL, reporter: RecordingReporter) -> CodableWeatherCache {
        CodableWeatherCache(
            records: TestSupport.recordStore(in: directory(in: root), reporter: reporter),
            keys: PrefixedCityKey(prefix: StorageStandard.weatherKeyPrefix)
        )
    }
}
