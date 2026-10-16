//
//  UtilsTests.swift
//  UtilsTests
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation
import Testing
import Utils

@Suite("Clamped")
struct ClampedTests {
    @Test("Values outside the range snap to its bounds", arguments: zip([-5, 0, 42, 100, 130], [0, 0, 42, 100, 100]))
    func clamps(value: Int, expected: Int) {
        #expect(value.clamped(to: 0...100) == expected)
    }
}

@Suite("Error classification")
struct ErrorClassificationTests {
    @Test("Connectivity errors are told apart from other failures")
    func connectivity() {
        #expect(URLError(.notConnectedToInternet).isConnectivity)
        #expect(URLError(.timedOut).isConnectivity)
        #expect(!URLError(.badServerResponse).isConnectivity)
        #expect(!CancellationError().isConnectivity)
    }

    @Test("Task and URL cancellations both count as cancellation")
    func cancellation() {
        #expect(CancellationError().isCancellation)
        #expect(URLError(.cancelled).isCancellation)
        #expect(!URLError(.notConnectedToInternet).isCancellation)
    }
}

@Suite("String")
struct StringTests {
    @Test("Two-letter region codes become flags, anything else doesn't")
    func regionalIndicatorFlag() {
        #expect("PT".regionalIndicatorFlag == "🇵🇹")
        #expect("pl".regionalIndicatorFlag == "🇵🇱")
        #expect("PRT".regionalIndicatorFlag == nil)
        #expect("P1".regionalIndicatorFlag == nil)
        #expect("".regionalIndicatorFlag == nil)
    }

    @Test("The leading component is the trimmed text before the first separator")
    func leadingComponent() {
        #expect("Paris, France".leadingComponent(separatedBy: ",") == "Paris")
        #expect("  Lis ".leadingComponent(separatedBy: ",") == "Lis")
        #expect("".leadingComponent(separatedBy: ",") == nil)
    }

    @Test("Prefix matching ignores case and diacritics but stays anchored")
    func prefixMatching() {
        #expect("Zürich".hasPrefixIgnoringCaseAndDiacritics("zur"))
        #expect("Lisbon".hasPrefixIgnoringCaseAndDiacritics("LIS"))
        #expect(!"Lisbon".hasPrefixIgnoringCaseAndDiacritics("bon"))
        #expect(!"Lisbon".hasPrefixIgnoringCaseAndDiacritics(""))
    }
}

@Suite("AttributedString prefix")
struct AttributedStringPrefixTests {
    private let bold = AttributeContainer().inlinePresentationIntent(.stronglyEmphasized)

    private func boldText(in string: AttributedString) -> String {
        string.runs
            .filter { $0.inlinePresentationIntent == .stronglyEmphasized }
            .map { String(string[$0.range].characters) }
            .joined()
    }

    @Test("Only the matching prefix gets the attributes")
    func appliesToPrefix() {
        let result = AttributedString("Lisbon").applying(bold, toPrefixMatching: "lis")
        #expect(boldText(in: result) == "Lis")
        #expect(String(result.characters) == "Lisbon")
    }

    @Test("An empty or non-matching prefix leaves the string unchanged")
    func leavesOthersAlone() {
        #expect(boldText(in: AttributedString("Lisbon").applying(bold, toPrefixMatching: "")) == "")
        #expect(boldText(in: AttributedString("Lisbon").applying(bold, toPrefixMatching: "bon")) == "")
    }
}

@Suite("Calendar")
struct CalendarTests {
    @Test("A gregorian calendar carries the given time zone and locale")
    func gregorian() throws {
        let lisbon = try #require(TimeZone(identifier: "Europe/Lisbon"))
        let calendar = Calendar.gregorian(timeZone: lisbon, locale: Locale(identifier: "en_GB"))
        #expect(calendar.identifier == .gregorian)
        #expect(calendar.timeZone == lisbon)
        #expect(calendar.locale == Locale(identifier: "en_GB"))
        #expect(Calendar.gregorian(timeZone: lisbon).timeZone == lisbon)
    }
}
