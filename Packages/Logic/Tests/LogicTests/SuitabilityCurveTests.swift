//
//  SuitabilityCurveTests.swift
//  LogicTests
//
//  Created by Kamil Misiag on 17/10/2026.
//

import Logic
import Testing

@Suite("Suitability curves")
struct SuitabilityCurveTests {
    @Test("A descending ramp is full up to its first bound, empty from its second and linear in between")
    func descendingRamp() {
        let ramp = DescendingRamp(fullUntil: 10, zeroFrom: 30)
        #expect(ratings(of: ramp, at: [-5, 10, 15, 20, 25, 30, 45]) == [1, 1, 0.75, 0.5, 0.25, 0, 0])
    }

    @Test("A descending ramp whose bounds meet or cross is a step down after its first bound")
    func descendingStep() {
        #expect(ratings(of: DescendingRamp(fullUntil: 10, zeroFrom: 10), at: [9, 10, 10.5, 20]) == [1, 1, 0, 0])
        #expect(ratings(of: DescendingRamp(fullUntil: 10, zeroFrom: 4), at: [3, 7, 10, 11]) == [1, 1, 1, 0])
    }

    @Test("A descending ramp rates NaN as zero and infinities as its ends")
    func descendingNonFinite() {
        #expect(ratings(of: DescendingRamp(fullUntil: 10, zeroFrom: 30), at: [.nan, -.infinity, .infinity]) == [0, 1, 0])
    }

    @Test("An ascending ramp is empty up to its first bound, full from its second and linear in between")
    func ascendingRamp() {
        let ramp = AscendingRamp(zeroUntil: 0, fullFrom: 10)
        #expect(ratings(of: ramp, at: [-5, 0, 2.5, 5, 7.5, 10, 20]) == [0, 0, 0.25, 0.5, 0.75, 1, 1])
    }

    @Test("An ascending ramp whose bounds meet or cross is a step up after its first bound")
    func ascendingStep() {
        #expect(ratings(of: AscendingRamp(zeroUntil: 5, fullFrom: 5), at: [4, 5, 5.5, 9]) == [0, 0, 1, 1])
        #expect(ratings(of: AscendingRamp(zeroUntil: 5, fullFrom: 1), at: [1, 3, 5, 6]) == [0, 0, 0, 1])
    }

    @Test("An ascending ramp rates NaN as zero and infinities as its ends")
    func ascendingNonFinite() {
        #expect(ratings(of: AscendingRamp(zeroUntil: 0, fullFrom: 10), at: [.nan, -.infinity, .infinity]) == [0, 0, 1])
    }

    @Test("A comfort band is full across its ideal range and falls linearly to zero on either side")
    func comfortBand() {
        let band = ComfortBand(ideal: 18...30, zeroBelow: 8, zeroAbove: 40)
        #expect(ratings(of: band, at: [0, 8, 10.5, 13, 18, 24, 30]) == [0, 0, 0.25, 0.5, 1, 1, 1])
        #expect(ratings(of: band, at: [35, 37.5, 40, 50]) == [0.5, 0.25, 0, 0])
    }

    @Test("A comfort band around a single ideal value still falls off on both sides")
    func comfortPoint() {
        #expect(ratings(of: ComfortBand(ideal: 20...20, zeroBelow: 10, zeroAbove: 30), at: [15, 20, 25]) == [0.5, 1, 0.5])
    }

    @Test("A comfort band edge that doesn't reach beyond the ideal range is a step")
    func comfortSteps() {
        #expect(ratings(of: ComfortBand(ideal: 18...30, zeroBelow: 18, zeroAbove: 30), at: [17.5, 18, 30, 30.5]) == [0, 1, 1, 0])
        #expect(ratings(of: ComfortBand(ideal: 18...30, zeroBelow: 25, zeroAbove: 20), at: [17, 18, 24, 30, 31]) == [0, 1, 1, 1, 0])
    }

    @Test("A comfort band rates NaN and infinities as zero")
    func comfortNonFinite() {
        #expect(ratings(of: ComfortBand(ideal: 18...30, zeroBelow: 8, zeroAbove: 40), at: [.nan, -.infinity, .infinity]) == [0, 0, 0])
    }

    @Test("Infinite bounds behave as endless ramps and never produce NaN")
    func infiniteBounds() {
        #expect(DescendingRamp(fullUntil: 0, zeroFrom: .infinity).suitability(of: 1e9) == 1)
        #expect(AscendingRamp(zeroUntil: -.infinity, fullFrom: 0).suitability(of: -1e9) == 1)
        #expect(ratings(of: ComfortBand(ideal: 0...10, zeroBelow: -.infinity, zeroAbove: .infinity), at: [-1e9, 1e9]) == [1, 1])
        #expect(DescendingRamp(fullUntil: -.infinity, zeroFrom: .infinity).suitability(of: 0) == 0)
        #expect(AscendingRamp(zeroUntil: 0, fullFrom: .infinity).suitability(of: 1e9) == 0)
    }

    private func ratings(of curve: any SuitabilityCurve, at values: [Double]) -> [Double] {
        values.map(curve.suitability(of:))
    }
}
