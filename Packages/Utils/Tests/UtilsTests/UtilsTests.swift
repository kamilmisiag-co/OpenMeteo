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

@Suite("Uniqued")
struct UniquedTests {
    @Test("The first element for each key is kept, in the original order")
    func keepsFirstPerKey() {
        let words = ["apple", "avocado", "banana", "blueberry", "cherry", "apricot"]
        #expect(words.uniqued { $0.first } == ["apple", "banana", "cherry"])
        #expect([3, 1, 3, 2, 1].uniqued { $0 } == [3, 1, 2])
        #expect([Int]().uniqued { $0 }.isEmpty)
    }

    @Test("The key is computed once per element and its errors are rethrown")
    func evaluatesKeyOnce() throws {
        var evaluated: [Int] = []
        let unique = [1, 2, 1, 3].uniqued { value in
            evaluated.append(value)
            return value
        }
        #expect(unique == [1, 2, 3])
        #expect(evaluated == [1, 2, 1, 3])
        #expect(throws: URLError(.badURL)) {
            try [1, 2].uniqued { (_: Int) throws -> Int in throw URLError(.badURL) }
        }
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

    @Test("Wrapping errors are classified by the error they wrap")
    func underlyingErrors() {
        #expect(WrappingError(underlyingError: URLError(.notConnectedToInternet)).isConnectivity)
        #expect(WrappingError(underlyingError: CancellationError()).isCancellation)
        #expect(!WrappingError(underlyingError: nil).isConnectivity)
        #expect(!WrappingError(underlyingError: nil).isCancellation)
        #expect(WrappingError(underlyingError: WrappingError(underlyingError: URLError(.timedOut))).isConnectivity)
    }

    @Test("Wrappers that point back at themselves or each other terminate")
    func cyclicWrappers() {
        #expect(!SelfWrappingError().isConnectivity)
        #expect(!SelfWrappingError().isCancellation)
        #expect(!LoopingErrorA().isConnectivity)
        #expect(!LoopingErrorB().isCancellation)
        #expect(!ChangingLoopError().isConnectivity)
    }

    @Test("A wrapped URL cancellation is not task cancellation")
    func wrappedURLCancellation() {
        #expect(!WrappingError(underlyingError: URLError(.cancelled)).isCancellation)
        #expect(URLError(.cancelled).isCancellation)
    }

    @Test("Wrappers that print like the error they wrap are still unwrapped")
    func echoingWrapper() {
        #expect(EchoingError(underlyingError: WrappingError(underlyingError: URLError(.notConnectedToInternet))).isConnectivity)
    }
}

struct WrappingError: UnderlyingErrorProviding {
    let underlyingError: (any Error)?
}

struct SelfWrappingError: UnderlyingErrorProviding {
    var underlyingError: (any Error)? { self }
}

struct LoopingErrorA: UnderlyingErrorProviding {
    var underlyingError: (any Error)? { LoopingErrorB() }
}

struct LoopingErrorB: UnderlyingErrorProviding {
    var underlyingError: (any Error)? { LoopingErrorA() }
}

struct ChangingLoopError: UnderlyingErrorProviding {
    let id = UUID()
    var underlyingError: (any Error)? { ChangingLoopError() }
}

struct EchoingError: UnderlyingErrorProviding, CustomDebugStringConvertible {
    let underlyingError: (any Error)?
    var debugDescription: String { underlyingError.map { String(reflecting: $0) } ?? "" }
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
