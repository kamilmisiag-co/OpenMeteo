//
//  ForecastField.swift
//  OpenMeteoAPI
//
//  Created by Kamil Misiag on 19/10/2026.
//

public protocol ForecastField: CodingKey, CaseIterable, Hashable, RawRepresentable<String>, Sendable {
    static var time: Self { get }
}

extension ForecastField {
    public var isRequested: Bool {
        self != .time
    }

    public static var requestedNames: [String] {
        allCases.filter(\.isRequested).map(\.rawValue)
    }
}
