import Foundation

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
        guard !query.isEmpty else { return 1 }

        let q = Array(query.lowercased())
        let c = Array(candidate.lowercased())
        var qi = 0
        var score = 0
        var consecutive = 0
        var lastMatchIdx = -2

        for ci in 0..<c.count {
            if qi < q.count && c[ci] == q[qi] {
                qi += 1
                consecutive = (ci == lastMatchIdx + 1) ? consecutive + 1 : 1
                score += consecutive
                if ci == qi - 1 { score += 2 }  // prefix bonus
                lastMatchIdx = ci
            }
        }

        return qi == q.count ? score : nil
    }

    /// Filters `candidates` against `query` and returns matches sorted by descending score.
    public static func rank(query: String, candidates: [String]) -> [String] {
        candidates
            .compactMap { tag -> (tag: String, score: Int)? in
                guard let score = match(query: query, candidate: tag) else { return nil }
                return (tag, score)
            }
            .sorted { $0.score > $1.score }
            .map(\.tag)
    }
}
