//
//  CodableRecentCitiesStore.swift
//  Storage
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic

public struct CodableRecentCitiesStore: RecentCitiesStoring {
    private let records: any RecordStoring
    private let key: String

    public init(records: any RecordStoring, key: String) {
        self.records = records
        self.key = key
    }

    public func load() -> [City] {
        records.record([City].self, forKey: key) ?? []
    }

    public func save(_ cities: [City]) {
        records.save(cities, forKey: key)
    }
}
