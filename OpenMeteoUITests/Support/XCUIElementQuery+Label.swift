//
//  XCUIElementQuery+Label.swift
//  OpenMeteoUITests
//
//  Created by Kamil Misiag on 19/10/2026.
//

import XCTest

extension XCUIElementQuery {
    func labelled(containing text: String) -> XCUIElement {
        matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }
}
