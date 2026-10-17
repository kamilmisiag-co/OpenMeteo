//
//  RecentCitiesServiceTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic
import LogicMocks
import Testing

@Suite("Recent cities service")
struct RecentCitiesServiceTests {
    @Test("Recent cities are read from the store without saving")
    func readsStore() {
        let store = InMemoryRecentCitiesStore(cities: [Fixtures.lisbon, Fixtures.bergen])
        #expect(RecentCitiesService(store: store, maximumCount: 3).recentCities() == [Fixtures.lisbon, Fixtures.bergen])
        #expect(store.saveCount == 0)
    }

    @Test("Reading drops duplicates and extra entries from the result but leaves the store alone")
    func readNormalizes() {
        let stored = [Fixtures.lisbon, Fixtures.bergen, Fixtures.lisboa, Fixtures.zakopane, Fixtures.auckland]
        let store = InMemoryRecentCitiesStore(cities: stored)
        #expect(RecentCitiesService(store: store, maximumCount: 3).recentCities() == [Fixtures.lisbon, Fixtures.bergen, Fixtures.zakopane])
        #expect(store.cities == stored)
        #expect(store.saveCount == 0)
    }

    @Test("Visiting a city with no history saves it")
    func firstVisit() {
        let store = InMemoryRecentCitiesStore(cities: [])
        #expect(RecentCitiesService(store: store, maximumCount: 3).recordVisit(to: Fixtures.lisbon) == [Fixtures.lisbon])
        #expect(store.cities == [Fixtures.lisbon])
        #expect(store.saveCount == 1)
    }

    @Test("A newly visited city goes first and the rest keep their order")
    func newCityFirst() {
        let store = InMemoryRecentCitiesStore(cities: [Fixtures.bergen, Fixtures.zakopane])
        let result = RecentCitiesService(store: store, maximumCount: 3).recordVisit(to: Fixtures.lisbon)
        #expect(result == [Fixtures.lisbon, Fixtures.bergen, Fixtures.zakopane])
        #expect(store.cities == result)
        #expect(store.saveCount == 1)
    }

    @Test("Revisiting a city moves it to the front without duplicating it")
    func revisitMovesToFront() {
        let store = InMemoryRecentCitiesStore(cities: [Fixtures.bergen, Fixtures.lisbon, Fixtures.zakopane])
        let result = RecentCitiesService(store: store, maximumCount: 3).recordVisit(to: Fixtures.lisbon)
        #expect(result == [Fixtures.lisbon, Fixtures.bergen, Fixtures.zakopane])
        #expect(store.cities == result)
        #expect(store.saveCount == 1)
    }

    @Test("Revisiting a city with updated details keeps the new details")
    func updatedDetails() {
        let store = InMemoryRecentCitiesStore(cities: [Fixtures.bergen, Fixtures.lisbon])
        #expect(RecentCitiesService(store: store, maximumCount: 3).recordVisit(to: Fixtures.lisboa) == [Fixtures.lisboa, Fixtures.bergen])
        #expect(store.cities == [Fixtures.lisboa, Fixtures.bergen])

        let alreadyFirst = InMemoryRecentCitiesStore(cities: [Fixtures.lisbon, Fixtures.bergen])
        #expect(RecentCitiesService(store: alreadyFirst, maximumCount: 3).recordVisit(to: Fixtures.lisboa) == [Fixtures.lisboa, Fixtures.bergen])
        #expect(alreadyFirst.cities == [Fixtures.lisboa, Fixtures.bergen])
        #expect(alreadyFirst.saveCount == 1)
    }

    @Test("Revisiting the most recent city with the same details doesn't save")
    func unchangedVisit() {
        let store = InMemoryRecentCitiesStore(cities: [Fixtures.lisbon, Fixtures.bergen])
        #expect(RecentCitiesService(store: store, maximumCount: 3).recordVisit(to: Fixtures.lisbon) == [Fixtures.lisbon, Fixtures.bergen])
        #expect(store.saveCount == 0)
    }

    @Test("The oldest cities are dropped once the maximum is reached")
    func truncation() {
        let store = InMemoryRecentCitiesStore(cities: [Fixtures.bergen, Fixtures.zakopane])
        #expect(RecentCitiesService(store: store, maximumCount: 2).recordVisit(to: Fixtures.lisbon) == [Fixtures.lisbon, Fixtures.bergen])
        #expect(store.cities == [Fixtures.lisbon, Fixtures.bergen])
    }

    @Test("Visits build a most-recent-first history and only save when it changes")
    func visitHistory() {
        let store = InMemoryRecentCitiesStore(cities: [])
        let service = RecentCitiesService(store: store, maximumCount: 3)
        for city in [Fixtures.lisbon, Fixtures.bergen, Fixtures.zakopane, Fixtures.bergen, Fixtures.auckland] {
            _ = service.recordVisit(to: city)
        }
        #expect(service.recentCities() == [Fixtures.auckland, Fixtures.bergen, Fixtures.zakopane])
        #expect(store.saveCount == 5)
        _ = service.recordVisit(to: Fixtures.auckland)
        #expect(store.saveCount == 5)
    }

    @Test("A visit repairs a store holding duplicates or too many entries")
    func visitRepairsStore() {
        let store = InMemoryRecentCitiesStore(cities: [Fixtures.bergen, Fixtures.zakopane, Fixtures.bergen, Fixtures.auckland, Fixtures.noTimeZone])
        let result = RecentCitiesService(store: store, maximumCount: 3).recordVisit(to: Fixtures.lisbon)
        #expect(result == [Fixtures.lisbon, Fixtures.bergen, Fixtures.zakopane])
        #expect(store.cities == result)
        #expect(store.saveCount == 1)
    }

    @Test("Revisiting the most recent city still saves when the store needs repairing")
    func unchangedVisitRepairsStore() {
        let store = InMemoryRecentCitiesStore(cities: [Fixtures.lisbon, Fixtures.bergen, Fixtures.lisbon, Fixtures.zakopane])
        #expect(RecentCitiesService(store: store, maximumCount: 2).recordVisit(to: Fixtures.lisbon) == [Fixtures.lisbon, Fixtures.bergen])
        #expect(store.cities == [Fixtures.lisbon, Fixtures.bergen])
        #expect(store.saveCount == 1)
    }

    @Test("A maximum of zero or less keeps no recent cities", arguments: [0, -1, -10])
    func nonPositiveMaximum(maximumCount: Int) {
        let empty = InMemoryRecentCitiesStore(cities: [])
        let emptyService = RecentCitiesService(store: empty, maximumCount: maximumCount)
        #expect(emptyService.recordVisit(to: Fixtures.lisbon).isEmpty)
        #expect(emptyService.recentCities().isEmpty)
        #expect(empty.saveCount == 0)

        let filled = InMemoryRecentCitiesStore(cities: [Fixtures.bergen])
        let filledService = RecentCitiesService(store: filled, maximumCount: maximumCount)
        #expect(filledService.recentCities().isEmpty)
        #expect(filled.saveCount == 0)
        #expect(filledService.recordVisit(to: Fixtures.lisbon).isEmpty)
        #expect(filled.cities.isEmpty)
        #expect(filled.saveCount == 1)
    }

    @Test("Removing a city drops it and keeps the order of the rest")
    func removeOne() {
        let store = InMemoryRecentCitiesStore(cities: [Fixtures.lisbon, Fixtures.bergen, Fixtures.zakopane])
        #expect(RecentCitiesService(store: store, maximumCount: 3).remove([Fixtures.bergen.id]) == [Fixtures.lisbon, Fixtures.zakopane])
        #expect(store.cities == [Fixtures.lisbon, Fixtures.zakopane])
        #expect(store.saveCount == 1)
    }

    @Test("Several cities can be removed at once, ignoring unknown ids")
    func removeSeveral() {
        let store = InMemoryRecentCitiesStore(cities: [Fixtures.lisbon, Fixtures.bergen, Fixtures.zakopane])
        let result = RecentCitiesService(store: store, maximumCount: 3).remove([Fixtures.lisbon.id, Fixtures.zakopane.id, 42])
        #expect(result == [Fixtures.bergen])
        #expect(store.cities == [Fixtures.bergen])
        #expect(store.saveCount == 1)
    }

    @Test("Removing every city leaves an empty list")
    func removeEverything() {
        let store = InMemoryRecentCitiesStore(cities: [Fixtures.lisbon, Fixtures.bergen])
        #expect(RecentCitiesService(store: store, maximumCount: 3).remove([Fixtures.lisbon.id, Fixtures.bergen.id]).isEmpty)
        #expect(store.cities.isEmpty)
        #expect(store.saveCount == 1)
    }

    @Test("Removing only unknown ids or no ids doesn't save", arguments: [Set<City.ID>([42, Fixtures.auckland.id]), []])
    func removeUnknown(cityIDs: Set<City.ID>) {
        let store = InMemoryRecentCitiesStore(cities: [Fixtures.lisbon, Fixtures.bergen])
        #expect(RecentCitiesService(store: store, maximumCount: 3).remove(cityIDs) == [Fixtures.lisbon, Fixtures.bergen])
        #expect(store.saveCount == 0)
    }

    @Test("Removing repairs a store holding duplicates even when nothing matches")
    func removeRepairsStore() {
        let store = InMemoryRecentCitiesStore(cities: [Fixtures.lisbon, Fixtures.bergen, Fixtures.lisboa])
        #expect(RecentCitiesService(store: store, maximumCount: 3).remove([42]) == [Fixtures.lisbon, Fixtures.bergen])
        #expect(store.cities == [Fixtures.lisbon, Fixtures.bergen])
        #expect(store.saveCount == 1)
    }

    @Test("Removing works on the visible list, so entries past the maximum don't come back")
    func removeBeyondMaximum() {
        let store = InMemoryRecentCitiesStore(cities: [Fixtures.lisbon, Fixtures.bergen, Fixtures.zakopane])
        #expect(RecentCitiesService(store: store, maximumCount: 2).remove([Fixtures.lisbon.id]) == [Fixtures.bergen])
        #expect(store.cities == [Fixtures.bergen])
    }

    @Test("Clearing a non-empty history saves an empty list")
    func clearHistory() {
        let store = InMemoryRecentCitiesStore(cities: [Fixtures.lisbon, Fixtures.bergen])
        let service = RecentCitiesService(store: store, maximumCount: 3)
        service.removeAll()
        #expect(store.cities.isEmpty)
        #expect(store.saveCount == 1)
        #expect(service.recentCities().isEmpty)
    }

    @Test("Clearing an empty history doesn't save")
    func clearEmptyHistory() {
        let store = InMemoryRecentCitiesStore(cities: [])
        RecentCitiesService(store: store, maximumCount: 3).removeAll()
        #expect(store.saveCount == 0)
    }
}
