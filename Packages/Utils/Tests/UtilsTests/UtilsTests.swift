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

@Suite("Clamped if NaN")
struct NaNClampedTests {
    @Test("NaN gives the fallback")
    func nanFallback() {
        #expect(Double.nan.clamped(to: 0...1, ifNaN: 0.5) == 0.5)
        #expect(Double.nan.clamped(to: 0...1, ifNaN: 0) == 0)
        #expect(Double.nan.clamped(to: 0...1, ifNaN: 1) == 1)
        #expect(Double.signalingNaN.clamped(to: 0...1, ifNaN: 0.5) == 0.5)
    }

    @Test("A fallback outside the range is clamped too, so the result always lies in the range")
    func fallbackOutsideRange() {
        #expect(Double.nan.clamped(to: 0...1, ifNaN: 7) == 1)
        #expect(Double.nan.clamped(to: 0...1, ifNaN: -3) == 0)
        #expect(Double.nan.clamped(to: 0...1, ifNaN: .infinity) == 1)
        #expect(Double.nan.clamped(to: 0...1, ifNaN: .nan) == 0)
        #expect(Double.nan.clamped(to: 2...3, ifNaN: .nan) == 2)
        #expect(Double(0.5).clamped(to: 0...1, ifNaN: .nan) == 0.5)
    }

    @Test("Infinities snap to the bounds of the range")
    func infinities() {
        #expect(Double.infinity.clamped(to: 0...1, ifNaN: 0.5) == 1)
        #expect((-Double.infinity).clamped(to: 0...1, ifNaN: 0.5) == 0)
    }

    @Test("Finite values behave like clamped(to:)", arguments: zip([-5, 0, 0.25, 1, 3.5], [0, 0, 0.25, 1, 1]))
    func finite(value: Double, expected: Double) {
        #expect(value.clamped(to: 0...1, ifNaN: 0.5) == expected)
        #expect(value.clamped(to: 0...1, ifNaN: 0.5) == value.clamped(to: 0...1))
    }

    @Test("Float values are clamped the same way")
    func float() {
        #expect(Float.nan.clamped(to: 0...1, ifNaN: 0.5) == 0.5)
        #expect(Float.infinity.clamped(to: 0...1, ifNaN: 0.5) == 1)
        #expect((-Float.infinity).clamped(to: 0...1, ifNaN: 0.5) == 0)
        #expect(Float(0.75).clamped(to: 0...1, ifNaN: 0.5) == 0.75)
        #expect(Float(-2).clamped(to: 0...1, ifNaN: 0.5) == 0)
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

@Suite("Uniqued elements")
struct UniquedElementsTests {
    @Test("Hashable elements keep their first occurrence, in order")
    func keepsFirstOccurrence() {
        #expect([3, 1, 3, 2, 1].uniqued() == [3, 1, 2])
        #expect(["b", "a", "b"].uniqued() == ["b", "a"])
        #expect([Int]().uniqued().isEmpty)
    }
}

@Suite("Consecutive runs")
struct ConsecutiveRunsTests {
    @Test("Ascending neighbours join into one run and gaps start a new one")
    func runs() {
        #expect([0, 1, 2, 4, 6, 7].consecutiveRuns() == [0...2, 4...4, 6...7])
        #expect([5].consecutiveRuns() == [5...5])
        #expect([Int]().consecutiveRuns().isEmpty)
    }

    @Test("Values are sorted and repeats are ignored before runs are formed")
    func unsortedInput() {
        #expect([2, 2, 3].consecutiveRuns() == [2...3])
        #expect([3, 2, 1, 7].consecutiveRuns() == [1...3, 7...7])
    }

    @Test("Values at the edges of the integer range do not overflow")
    func edges() {
        #expect([Int.max - 1, Int.max].consecutiveRuns() == [(Int.max - 1)...Int.max])
        #expect([Int.max, Int.min].consecutiveRuns() == [Int.min...Int.min, Int.max...Int.max])
        #expect([UInt8(0), 1, 255].consecutiveRuns() == [0...1, 255...255])
    }
}

@Suite("Min and max")
struct MinAndMaxTests {
    @Test("The smallest and largest elements come back together")
    func bounds() throws {
        let bounds = try #require([4.5, -1, 9, 3].minAndMax())
        #expect(bounds.min == -1)
        #expect(bounds.max == 9)
        let single = try #require(["m"].minAndMax())
        #expect(single.min == "m" && single.max == "m")
    }

    @Test("An empty sequence has no bounds")
    func empty() {
        #expect([Int]().minAndMax() == nil)
    }
}

@Suite("Most frequent case")
struct MostFrequentCaseTests {
    private enum Weather: CaseIterable, Hashable {
        case rain, wind, snow
    }

    private enum Priority: CaseIterable, Hashable {
        case low, high

        static var allCases: [Priority] {
            [.high, .low]
        }
    }

    private enum Season: CaseIterable, Hashable {
        case spring, autumn, winter

        static var allCases: [Season] {
            [.spring]
        }
    }

    @Test("The case that occurs most often wins")
    func mostFrequent() {
        #expect([Weather.snow, .wind, .snow].mostFrequentCase() == .snow)
        #expect([Weather.wind].mostFrequentCase() == .wind)
    }

    @Test("Ties go to the case listed first in allCases, whatever the order of occurrence")
    func ties() {
        #expect([Weather.snow, .wind, .wind, .snow].mostFrequentCase() == .wind)
        #expect([Weather.snow, .rain].mostFrequentCase() == .rain)
        #expect([Priority.low, .high].mostFrequentCase() == .high)
    }

    @Test("An empty sequence has no most frequent case")
    func empty() {
        #expect([Weather]().mostFrequentCase() == nil)
    }

    @Test("Only the cases listed in allCases are counted")
    func unlistedCase() {
        #expect([Season.autumn, .autumn, .spring].mostFrequentCase() == .spring)
        #expect([Season.autumn, .winter].mostFrequentCase() == nil)
    }
}

@Suite("Valid indices")
struct ValidIndicesTests {
    private let values = [10, 20, 30, 40]

    @Test("Candidates come back sorted, without duplicates or indices outside the collection")
    func filters() {
        #expect(values.validIndices(among: [3, 1, 3, -1, 4, 0]) == [0, 1, 3])
        #expect(values.validIndices(among: []).isEmpty)
        #expect([Int]().validIndices(among: [0, 1]).isEmpty)
    }

    @Test("A slice keeps its own indices")
    func slice() {
        #expect(values[1...2].validIndices(among: [0, 1, 2, 3]) == [1, 2])
    }
}

@Suite("Rounding")
struct RoundingTests {
    @Test("Rounded integers round halves away from zero and exist only for finite values in range", arguments: [
        (22.5, 23),
        (-2.5, -3),
        (-0.4, 0),
        (-3.6, -4),
        (Double(Int.min), Int.min),
        (Double(Int.max), nil),
        (1e300, nil),
    ] as [(Double, Int?)])
    func roundedInt(value: Double, expected: Int?) {
        #expect(value.roundedInt() == expected)
    }

    @Test("Values that are not finite have no rounded integer")
    func nonFinite() {
        #expect(Double.nan.roundedInt() == nil)
        #expect(Double.infinity.roundedInt() == nil)
        #expect((-Double.infinity).roundedInt() == nil)
    }

    @Test("Float values round the same way")
    func float() {
        #expect(Float(2.5).roundedInt() == 3)
        #expect(Float(-0.6).roundedInt() == -1)
        #expect(Float.nan.roundedInt() == nil)
    }
}

@Suite("Element at index")
struct ElementAtIndexTests {
    private let values = [10, 20, 30]

    @Test("An index inside the collection returns its element")
    func inRange() {
        #expect(values.element(at: 0) == 10)
        #expect(values.element(at: 1) == 20)
        #expect(values.element(at: 2) == 30)
    }

    @Test("Indices before the start or past the end return nil", arguments: [-1, -10, 3, 4])
    func outOfRange(index: Int) {
        #expect(values.element(at: index) == nil)
    }

    @Test("An empty collection has no element at any index")
    func empty() {
        #expect([Int]().element(at: 0) == nil)
        #expect([Int]().element(at: -1) == nil)
    }

    @Test("A stored nil comes back wrapped, unlike a missing element")
    func storedNil() {
        let optionals: [Int?] = [nil, 1]
        #expect(optionals.element(at: 0) == .some(nil))
        #expect(optionals.element(at: 1) == .some(1))
        #expect(optionals.element(at: 2) == nil)
    }

    @Test("A slice is looked up by its own indices, not from zero")
    func slice() {
        let slice = [10, 20, 30, 40][1...2]
        #expect(slice.element(at: 0) == nil)
        #expect(slice.element(at: 1) == 20)
        #expect(slice.element(at: 2) == 30)
        #expect(slice.element(at: 3) == nil)
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

@Suite("ASCII digits")
struct ASCIIDigitsTests {
    @Test("Non-empty runs of 0 to 9 are ASCII digits", arguments: ["0", "0123456789"])
    func digits(text: String) {
        #expect(text.isASCIIDigits)
    }

    @Test("Empty text, signs, spaces, separators and non-ASCII digits are not", arguments: ["", "+1", "-1", " 1", "1.5", "١", "１", "½", "1\u{301}", "\r\n"])
    func nonDigits(text: String) {
        #expect(!text.isASCIIDigits)
    }

    @Test("A substring is checked by its own scalars only")
    func substring() {
        let date = "2026-10-18"
        #expect(date.prefix(4).isASCIIDigits)
        #expect(!date.prefix(5).isASCIIDigits)
        #expect(date.split(separator: "-").map(\.isASCIIDigits) == [true, true, true])
        #expect(!date.dropFirst(10).isASCIIDigits)
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
