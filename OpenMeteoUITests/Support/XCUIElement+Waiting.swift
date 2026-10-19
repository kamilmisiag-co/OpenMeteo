//
//  XCUIElement+Waiting.swift
//  OpenMeteoUITests
//
//  Created by Kamil Misiag on 19/10/2026.
//

import XCTest

extension XCUIElement {
    private static let timeout: TimeInterval = 10

    @discardableResult
    func waitUntilExists(file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        XCTAssertTrue(waitForExistence(timeout: Self.timeout), "Timed out waiting for \(description)", file: file, line: line)
        return self
    }

    func waitUntilGone(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(waitForNonExistence(timeout: Self.timeout), "Still showing \(description)", file: file, line: line)
    }
}
