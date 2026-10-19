//
//  PreviewDateProvider.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

#if DEBUG
import Foundation
import Utils

nonisolated struct PreviewDateProvider: DateProviding {
    private let date: Date

    init(date: Date = PreviewForecasts.referenceNow) {
        self.date = date
    }

    func now() -> Date {
        date
    }
}
#endif
