//
//  SourcePublicationSortKey.swift
//  psychoheads
//

import Foundation

/// Comparable publication ordering: year → volume → issue → month → day → title → id.
/// Volume may be taken from the issue field, or from the month field when that value
/// isn't a calendar month/season (e.g. month "volume 1" with issue "The Pop Issue").
/// Issue number is preferred over month so thematic month values (e.g. "Style Issue")
/// don't break ordering when issue numbers are present.
struct SourcePublicationSortKey: Equatable {
    let year: Int
    let month: Int
    let day: Int
    let volume: Int
    let issueNumber: Int
    let hasParsableIssue: Bool
    let title: String
    let id: String
    
    init(source: Source) {
        year = Int(source.year.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        
        let monthOrdinal = Self.monthOrdinal(source.month)
        month = monthOrdinal
        day = Int((source.day ?? "").trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        
        // Volume/issue may live in the issue field, or (when month isn't a calendar month)
        // in the month field — e.g. month "volume 1" + issue "The Pop Issue".
        let fromIssue = Self.parseIssue(source.issue)
        let fromMonthField: (volume: Int, number: Int, parsable: Bool)
        if monthOrdinal == 0 {
            fromMonthField = Self.parseIssue(source.month)
        } else {
            fromMonthField = (0, 0, false)
        }
        
        var resolvedVolume = 0
        var resolvedNumber = 0
        var resolvedParsable = false
        
        if fromMonthField.parsable {
            resolvedVolume = fromMonthField.volume
            resolvedNumber = fromMonthField.number
            resolvedParsable = true
        }
        if fromIssue.parsable {
            if fromIssue.volume > 0 {
                // e.g. "Volume 3 No 59" or "Volume 1" — issue field owns volume (+ number if any)
                resolvedVolume = fromIssue.volume
                resolvedNumber = fromIssue.number
            } else {
                // Plain numeric issue like "59" — keep any volume taken from the month field
                resolvedNumber = fromIssue.number
            }
            resolvedParsable = true
        }
        
        volume = resolvedVolume
        issueNumber = resolvedNumber
        hasParsableIssue = resolvedParsable
        
        title = source.title.lowercased()
        id = source.id
    }
    
    /// Strict weak ordering used for all library sorts.
    /// Year first, then volume/issue number (when present) before month/day so thematic
    /// "months" like "Style Issue" don't scramble order for magazines that use issue numbers.
    static func compare(_ lhs: SourcePublicationSortKey, _ rhs: SourcePublicationSortKey) -> ComparisonResult {
        if lhs.year != rhs.year {
            return lhs.year < rhs.year ? .orderedAscending : .orderedDescending
        }
        
        // Prefer issue/volume over month whenever either side has a parsable issue.
        // Missing/unparsable issue sorts as (volume: 0, number: 0).
        if lhs.hasParsableIssue || rhs.hasParsableIssue {
            let leftVolume = lhs.hasParsableIssue ? lhs.volume : 0
            let rightVolume = rhs.hasParsableIssue ? rhs.volume : 0
            if leftVolume != rightVolume {
                return leftVolume < rightVolume ? .orderedAscending : .orderedDescending
            }
            let leftNumber = lhs.hasParsableIssue ? lhs.issueNumber : 0
            let rightNumber = rhs.hasParsableIssue ? rhs.issueNumber : 0
            if leftNumber != rightNumber {
                return leftNumber < rightNumber ? .orderedAscending : .orderedDescending
            }
        }
        
        if lhs.month != rhs.month {
            return lhs.month < rhs.month ? .orderedAscending : .orderedDescending
        }
        if lhs.day != rhs.day {
            return lhs.day < rhs.day ? .orderedAscending : .orderedDescending
        }
        
        if lhs.title != rhs.title {
            return lhs.title < rhs.title ? .orderedAscending : .orderedDescending
        }
        if lhs.id != rhs.id {
            return lhs.id < rhs.id ? .orderedAscending : .orderedDescending
        }
        return .orderedSame
    }
    
    /// Returns whether `lhs` should appear before `rhs` given mode and invert flag.
    /// - `isReversed == false`: Date newest-first; Title A→Z with newer dates first within a title
    /// - `isReversed == true`: Date oldest-first; Title Z→A with older dates first within a title
    static func shouldPrecede(
        _ lhs: Source,
        _ rhs: Source,
        mode: LibrarySourceSortMode,
        isReversed: Bool
    ) -> Bool {
        let left = SourcePublicationSortKey(source: lhs)
        let right = SourcePublicationSortKey(source: rhs)
        
        switch mode {
        case .alphabetical:
            if left.title != right.title {
                return isReversed ? left.title > right.title : left.title < right.title
            }
            // Same title: publication date follows Date-mode direction (!isReversed ⇒ newer first)
            switch compare(left, right) {
            case .orderedAscending: return isReversed
            case .orderedDescending: return !isReversed
            case .orderedSame: return false
            }
            
        case .publicationDate:
            switch compare(left, right) {
            case .orderedAscending: return isReversed
            case .orderedDescending: return !isReversed
            case .orderedSame: return false
            }
        }
    }
    
    // MARK: - Month / season
    
    private static func monthOrdinal(_ raw: String?) -> Int {
        let value = (raw ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !value.isEmpty else { return 0 }
        
        let months: [String: Int] = [
            "january": 1, "jan": 1,
            "february": 2, "feb": 2,
            "march": 3, "mar": 3,
            "april": 4, "apr": 4,
            "may": 5,
            "june": 6, "jun": 6,
            "july": 7, "jul": 7,
            "august": 8, "aug": 8,
            "september": 9, "sept": 9, "sep": 9,
            "october": 10, "oct": 10,
            "november": 11, "nov": 11,
            "december": 12, "dec": 12,
            "spring": 3,
            "summer": 6,
            "fall": 9, "autumn": 9,
            "winter": 12
        ]
        
        if let exact = months[value] { return exact }
        
        for (name, ordinal) in months.sorted(by: { $0.key.count > $1.key.count }) {
            if value.contains(name) { return ordinal }
        }
        return 0
    }
    
    // MARK: - Issue parsing
    
    private static func parseIssue(_ raw: String?) -> (volume: Int, number: Int, parsable: Bool) {
        let trimmed = (raw ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return (0, 0, false) }
        
        let lower = trimmed.lowercased()
        
        // Plain integer issue
        if let onlyNumber = Int(trimmed) {
            return (0, onlyNumber, true)
        }
        
        // Volume forms: "volume 1", "vol. 2", "vol 3 no 59", "volume iv", "vol.3#12"
        if let volume = extractVolume(from: lower) {
            let number = extractIssueNumber(from: lower) ?? 0
            return (volume, number, true)
        }
        
        // Lone "#59" without volume
        if let number = extractHashNumber(from: lower) {
            return (0, number, true)
        }
        
        // Free-text issues (e.g. "the country issue") — ignore for sorting
        return (0, 0, false)
    }
    
    /// Finds a volume value after "volume" / "vol." / "vol".
    private static func extractVolume(from lower: String) -> Int? {
        let markers = ["volume", "vol.", "vol"]
        guard let marker = markers.first(where: { lower.contains($0) }) else { return nil }
        guard let markerRange = lower.range(of: marker) else { return nil }
        
        let afterMarker = lower[markerRange.upperBound...]
            .drop(while: { $0 == "." || $0.isWhitespace })
        
        // Leading arabic digits
        let digitPrefix = String(afterMarker.prefix(while: { $0.isNumber }))
        if let value = Int(digitPrefix), !digitPrefix.isEmpty {
            return value
        }
        
        // Leading roman numerals (letters i,v,x,l,c,d,m only)
        let romanPrefix = String(afterMarker.prefix(while: { "ivxlcdm".contains($0) }))
        if let value = romanToInt(romanPrefix) {
            return value
        }
        
        return nil
    }
    
    /// Finds an issue/number after No / Number / # (not the volume itself).
    private static func extractIssueNumber(from lower: String) -> Int? {
        let patterns = ["number", "no.", "no", "#"]
        // Search after the volume marker so "vol 3" doesn't count as the issue number.
        let searchStart: String.Index
        if let volRange = lower.range(of: "volume")
            ?? lower.range(of: "vol.")
            ?? lower.range(of: "vol") {
            // Skip past volume token and its numeric/roman value
            var idx = volRange.upperBound
            while idx < lower.endIndex, lower[idx] == "." || lower[idx].isWhitespace {
                idx = lower.index(after: idx)
            }
            while idx < lower.endIndex, lower[idx].isNumber || "ivxlcdm".contains(lower[idx]) {
                idx = lower.index(after: idx)
            }
            searchStart = idx
        } else {
            searchStart = lower.startIndex
        }
        
        let searchRegion = String(lower[searchStart...])
        for pattern in patterns {
            guard let range = searchRegion.range(of: pattern) else { continue }
            let after = searchRegion[range.upperBound...]
                .drop(while: { $0 == "." || $0.isWhitespace })
            let digits = String(after.prefix(while: { $0.isNumber }))
            if let value = Int(digits), !digits.isEmpty {
                return value
            }
        }
        return nil
    }
    
    private static func extractHashNumber(from lower: String) -> Int? {
        guard let range = lower.range(of: "#") else { return nil }
        let after = lower[range.upperBound...]
            .drop(while: { $0.isWhitespace })
        let digits = String(after.prefix(while: { $0.isNumber }))
        return Int(digits)
    }
    
    private static func romanToInt(_ roman: String) -> Int? {
        let map: [Character: Int] = [
            "i": 1, "v": 5, "x": 10, "l": 50, "c": 100, "d": 500, "m": 1000
        ]
        let chars = Array(roman.lowercased())
        guard !chars.isEmpty, chars.allSatisfy({ map[$0] != nil }) else { return nil }
        
        var total = 0
        var previous = 0
        for char in chars.reversed() {
            let value = map[char]!
            if value < previous {
                total -= value
            } else {
                total += value
                previous = value
            }
        }
        return total > 0 ? total : nil
    }
}

enum LibrarySourceSortMode {
    case publicationDate
    case alphabetical
}
