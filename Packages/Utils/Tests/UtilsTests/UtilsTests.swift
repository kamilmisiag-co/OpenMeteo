//
//  UtilsTests.swift
//  UtilsTests
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation
import Testing
import Utils
import UtilsMocks

@Suite("Clamped")
struct ClampedTests {
    @Test("Values outside the range snap to its bounds", arguments: zip([-5, 42, 130], [0, 42, 100]))
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

    @Test("Finite values behave like clamped(to:)", arguments: zip([-5, 0.25, 3.5], [0, 0.25, 1]))
    func finite(value: Double, expected: Double) {
        #expect(value.clamped(to: 0...1, ifNaN: 0.5) == expected)
        #expect(value.clamped(to: 0...1, ifNaN: 0.5) == value.clamped(to: 0...1))
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
        (Double(Int.min), Int.min),
        (Double(Int.max), nil),
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

    @Test("Indices before the start or past the end return nil", arguments: [-1, 3])
    func outOfRange(index: Int) {
        #expect(values.element(at: index) == nil)
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

@Suite("Valid index")
struct ValidIndexTests {
    private let values = [10, 20, 30]

    @Test("An index inside the collection comes back unchanged", arguments: [2])
    func inRange(index: Int) {
        #expect(values.validIndex(index) == index)
    }

    @Test("Indices before the start or past the end give nil", arguments: [-1, 3])
    func outOfRange(index: Int) {
        #expect(values.validIndex(index) == nil)
    }

    @Test("A missing index gives nil")
    func missing() {
        #expect(values.validIndex(nil) == nil)
    }

    @Test("A slice is checked against its own indices, not from zero")
    func slice() {
        let slice = [10, 20, 30, 40][1...2]
        #expect(slice.validIndex(0) == nil)
        #expect(slice.validIndex(1) == 1)
        #expect(slice.validIndex(2) == 2)
        #expect(slice.validIndex(3) == nil)
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
        #expect(WrappedError(underlyingError: URLError(.notConnectedToInternet)).isConnectivity)
        #expect(WrappedError(underlyingError: CancellationError()).isCancellation)
        #expect(!WrappedError(underlyingError: nil).isConnectivity)
        #expect(!WrappedError(underlyingError: nil).isCancellation)
        #expect(WrappedError(underlyingError: WrappedError(underlyingError: URLError(.timedOut))).isConnectivity)
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
        #expect(!WrappedError(underlyingError: URLError(.cancelled)).isCancellation)
        #expect(URLError(.cancelled).isCancellation)
    }

    @Test("Wrappers that print like the error they wrap are still unwrapped")
    func echoingWrapper() {
        #expect(EchoingError(underlyingError: WrappedError(underlyingError: URLError(.notConnectedToInternet))).isConnectivity)
    }
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

@Suite("ASCII digits")
struct ASCIIDigitsTests {
    @Test("Non-empty runs of 0 to 9 are ASCII digits", arguments: ["0123456789"])
    func digits(text: String) {
        #expect(text.isASCIIDigits)
    }

    @Test("Empty text, signs, non-ASCII digits and combining marks are not", arguments: ["", "+1", "١", "1\u{301}"])
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

    @Test("The prefix matches ignoring case and diacritics, like String prefix matching")
    func ignoresCaseAndDiacritics() {
        let result = AttributedString("Zürich").applying(bold, toPrefixMatching: "ZUR")
        #expect(boldText(in: result) == "Zür")
        #expect("Zürich".hasPrefixIgnoringCaseAndDiacritics("ZUR"))
    }
}

@Suite("Sum")
struct SumTests {
    private struct Rating {
        let weight: Double
        let suitability: Double
    }

    private let ratings = [Rating(weight: 2, suitability: 0.5), Rating(weight: 1, suitability: 1), Rating(weight: 0.5, suitability: 0)]

    @Test("Elements add up, and an empty sequence sums to zero")
    func sum() {
        #expect([1, 2, 3, 4].sum() == 10)
        #expect(([0.5, 0.25, -1] as [Double]).sum() == -0.25)
        let durations: [Duration] = [.seconds(1), .milliseconds(500)]
        #expect(durations.sum() == Duration.milliseconds(1_500))
        #expect([Int]().sum() == 0)
        #expect([Double]().sum() == 0)
    }

    @Test("Elements are added from first to last, like reduce")
    func order() {
        let values = [1e16, 1, -1e16, 1]
        #expect(values.sum() == values.reduce(0, +))
        #expect(values.sum() == 1)
        #expect(values.reversed().sum() == 0)
    }

    @Test("The values picked from each element add up, and an empty sequence sums to zero")
    func sumOf() {
        #expect(ratings.sum(of: \.weight) == 3.5)
        #expect(ratings.sum { $0.weight * $0.suitability } == 2)
        #expect([Int?](arrayLiteral: 1, nil, 3).sum { $0 ?? 0 } == 4)
        #expect([Rating]().sum(of: \.weight) == 0)
    }

    @Test("The value is picked once per element, in order, and its errors are rethrown")
    func picksOncePerElement() {
        var picked: [Double] = []
        let total = ratings.sum { rating in
            picked.append(rating.weight)
            return rating.weight
        }
        #expect(total == 3.5)
        #expect(picked == [2, 1, 0.5])
        #expect(throws: UnrelatedError.failed) {
            try ratings.sum { (_: Rating) throws -> Double in throw UnrelatedError.failed }
        }
    }
}

@Suite("Fraction of a range")
struct FractionTests {
    @Test("Values inside the range map linearly from 0 at its lower bound to 1 at its upper bound", arguments: zip([10, 15, 20], [0, 0.5, 1]))
    func inside(value: Double, expected: Double) {
        #expect(value.fraction(of: 10...20) == expected)
    }

    @Test("Values outside the range clamp to 0 or 1", arguments: zip([9.99, 20.01], [0, 1] as [Double]))
    func outside(value: Double, expected: Double) {
        #expect(value.fraction(of: 10...20) == expected)
    }

    @Test("Infinities clamp to the ends and NaN gives 0")
    func nonFinite() {
        #expect(Double.infinity.fraction(of: 0...1) == 1)
        #expect((-Double.infinity).fraction(of: 0...1) == 0)
        #expect(Double.nan.fraction(of: 0...1) == 0)
        #expect(Double.signalingNaN.fraction(of: 0...1) == 0)
    }

    @Test("A zero-width range gives 0 at its bound and below it, and 1 above it")
    func zeroWidth() {
        #expect(5.0.fraction(of: 5...5) == 0)
        #expect(4.0.fraction(of: 5...5) == 0)
        #expect(6.0.fraction(of: 5...5) == 1)
    }
}

@Suite("Case index")
struct CaseIndexTests {
    private enum Weather: CaseIterable, Equatable {
        case rain, wind, snow
    }

    private enum Priority: CaseIterable, Equatable {
        case low, high

        static var allCases: [Priority] {
            [.high, .low]
        }
    }

    private enum Season: CaseIterable, Equatable {
        case spring, autumn, winter

        static var allCases: [Season] {
            [.spring]
        }
    }

    private enum Shift: CaseIterable, Equatable {
        typealias AllCases = ArraySlice<Shift>

        case night, day, evening

        static var allCases: ArraySlice<Shift> {
            [Shift.night, .day, .evening][1...]
        }
    }

    @Test("Each case reports its position in allCases")
    func positions() {
        #expect(Weather.rain.caseIndex == 0)
        #expect(Weather.wind.caseIndex == 1)
        #expect(Weather.snow.caseIndex == 2)
    }

    @Test("A custom allCases order decides the position")
    func customOrder() {
        #expect(Priority.high.caseIndex == 0)
        #expect(Priority.low.caseIndex == 1)
    }

    @Test("Cases missing from allCases come after every listed case")
    func unlistedCase() {
        #expect(Season.spring.caseIndex == 0)
        #expect(Season.autumn.caseIndex == 1)
        #expect(Season.winter.caseIndex == 1)
    }

    @Test("The position counts from the start of allCases, whatever its indices")
    func sliceIndices() {
        #expect(Shift.day.caseIndex == 0)
        #expect(Shift.evening.caseIndex == 1)
        #expect(Shift.night.caseIndex == 2)
    }
}
