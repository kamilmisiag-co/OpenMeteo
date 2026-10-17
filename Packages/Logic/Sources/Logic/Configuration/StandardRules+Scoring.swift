//
//  StandardRules+Scoring.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

extension StandardRules {
    public static let effectThresholds = EffectThresholds(helpsFrom: 0.75, hurtsBelow: 0.5)

    public static let skiing = WeightedActivityScorer(
        activity: .skiing,
        rules: [
            TemperatureRule(weight: 0.35, highCurve: ComfortBand(ideal: -10 ... -2, zeroBelow: -25, zeroAbove: 8)),
            SnowfallRule(weight: 0.25, snowfallCurve: AscendingRamp(zeroUntil: 0, fullFrom: 10)),
            WindRule(
                weight: 0.2,
                speedCurve: DescendingRamp(fullUntil: 25, zeroFrom: 60),
                gustCurve: DescendingRamp(fullUntil: 40, zeroFrom: 90)
            ),
            RainRule(weight: 0.2, probabilityCurve: DescendingRamp(fullUntil: 0.1, zeroFrom: 0.7), minimumHighCelsius: 1),
        ],
        blockers: [NoSnowBlocker(minimumDepthCm: 10, minimumSnowfallCm: 1)],
        polarity: .direct,
        baseline: 0,
        effectThresholds: effectThresholds
    )

    public static let surfing = WeightedActivityScorer(
        activity: .surfing,
        rules: [
            WindRule(
                weight: 0.45,
                speedCurve: DescendingRamp(fullUntil: 15, zeroFrom: 40),
                gustCurve: DescendingRamp(fullUntil: 25, zeroFrom: 60)
            ),
            TemperatureRule(weight: 0.3, highCurve: ComfortBand(ideal: 18...30, zeroBelow: 8, zeroAbove: 40)),
            RainRule(weight: 0.25, probabilityCurve: DescendingRamp(fullUntil: 0.2, zeroFrom: 0.9), minimumHighCelsius: nil),
        ],
        blockers: [ConditionBlocker(kind: .thunderstorm, conditions: [.thunderstorm])],
        polarity: .direct,
        baseline: 0,
        effectThresholds: effectThresholds
    )

    public static let outdoorSightseeing = WeightedActivityScorer(
        activity: .outdoorSightseeing,
        rules: sightseeingRules,
        blockers: [],
        polarity: .direct,
        baseline: 0,
        effectThresholds: effectThresholds
    )

    public static let indoorSightseeing = WeightedActivityScorer(
        activity: .indoorSightseeing,
        rules: sightseeingRules,
        blockers: [],
        polarity: .inverted,
        baseline: 0.3,
        effectThresholds: effectThresholds
    )

    public static let scorers: [any ActivityScoring] = [skiing, surfing, outdoorSightseeing, indoorSightseeing]

    private static let sightseeingRules: [any FactorRule] = [
        RainRule(weight: 0.5, probabilityCurve: DescendingRamp(fullUntil: 0.1, zeroFrom: 0.8), minimumHighCelsius: nil),
        TemperatureRule(weight: 0.25, highCurve: ComfortBand(ideal: 16...26, zeroBelow: 0, zeroAbove: 38)),
        WindRule(
            weight: 0.25,
            speedCurve: DescendingRamp(fullUntil: 20, zeroFrom: 50),
            gustCurve: DescendingRamp(fullUntil: 35, zeroFrom: 75)
        ),
    ]
}
