import Foundation

/// A fuzzy match result carrying the score and which candidate character
/// positions were matched, so the UI can highlight them.
public struct FuzzyMatch: Identifiable {
    public let tag: String
    public let score: Int
    public let matchedIndices: Set<Int>

    public var id: String { tag }

    public init(tag: String, score: Int, matchedIndices: Set<Int>) {
        self.tag = tag
        self.score = score
        self.matchedIndices = matchedIndices
    }
}

/// Subsequence fuzzy matcher for the recent-tags dropdown.
///
/// Scoring rewards:
/// - Consecutive character runs (each extra consecutive char adds more)
/// - Matches at the start of the candidate (prefix bonus +2)
///
/// Returns `nil` if any query character is not found in order, otherwise
/// an `Int` score — higher is better.
public enum FuzzyMatcher {

    public static func match(query: String, candidate: String) -> Int? {
        matchWithIndices(query: query, candidate: candidate)?.score
    }

    /// Like `match()` but also returns the indices of matched characters
    /// in the candidate, for rendering highlighted text.
    public static func matchWithIndices(query: String, candidate: String) -> (score: Int, indices: Set<Int>)? {
        guard !query.isEmpty else { return (1, []) }

        let q = Array(query.lowercased())
        let c = Array(candidate.lowercased())
        var qi = 0
        var score = 0
        var consecutive = 0
        var lastMatchIdx = -2
        var indices = Set<Int>()

        for ci in 0..<c.count {
            if qi < q.count && c[ci] == q[qi] {
                qi += 1
                consecutive = (ci == lastMatchIdx + 1) ? consecutive + 1 : 1
                score += consecutive
                if ci == qi - 1 { score += 2 }  // prefix bonus
                lastMatchIdx = ci
                indices.insert(ci)
            }
        }

        return qi == q.count ? (score, indices) : nil
    }

    /// Filters `candidates` against `query` and returns matches sorted by descending score.
    public static func rank(query: String, candidates: [String]) -> [String] {
        rankWithMatches(query: query, candidates: candidates).map(\.tag)
    }

    /// Like `rank()` but returns full `FuzzyMatch` results with match indices.
    public static func rankWithMatches(query: String, candidates: [String]) -> [FuzzyMatch] {
        candidates
            .compactMap { tag -> FuzzyMatch? in
                guard let result = matchWithIndices(query: query, candidate: tag) else { return nil }
                return FuzzyMatch(tag: tag, score: result.score, matchedIndices: result.indices)
            }
            .sorted { $0.score > $1.score }
    }
}
