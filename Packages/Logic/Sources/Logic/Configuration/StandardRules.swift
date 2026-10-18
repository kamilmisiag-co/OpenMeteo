//
//  StandardRules.swift
//  Logic
//
//  Created by Kamil Misiag on 17/10/2026.
//

public enum StandardRules {
    public static let forecastDayCount = 7
    public static let staleAfter = Duration.seconds(3 * 60 * 60)
    public static let tieBreakOrder: [Activity] = [.surfing, .outdoorSightseeing, .indoorSightseeing, .skiing]
    public static let minimumQueryLength = 2
    public static let querySeparators: Set<Character> = [",", "，", "、", "､", "﹐", "﹑", "،"]
    public static let queryInvisibleScalars: Set<Unicode.Scalar> = ["\u{200B}", "\u{FEFF}"]
    public static let maximumRecentCities = 10
    public static let searchDebounce = Duration.milliseconds(250)
    public static let strongScoreThreshold = 60
}
