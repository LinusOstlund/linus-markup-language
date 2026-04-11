/// LML Unit Tests
/// Run: swiftc LMLTests.swift -o LMLTests && ./LMLTests

import Foundation

// ─── Functions under test (mirrored from LML.swift) ─────────────────────────

func lmlXmlEscape(_ str: String) -> String {
    str
        .replacingOccurrences(of: "&",  with: "&amp;")
        .replacingOccurrences(of: "\"", with: "&quot;")
        .replacingOccurrences(of: "<",  with: "&lt;")
        .replacingOccurrences(of: ">",  with: "&gt;")
}

func lmlSanitizeActionType(_ raw: String) -> String {
    let lowered = raw.lowercased()
    let replaced = lowered.map { $0.isLetter || $0.isNumber ? $0 : Character("_") }
    var result = String(replaced)
    while result.contains("__") {
        result = result.replacingOccurrences(of: "__", with: "_")
    }
    result = result.trimmingCharacters(in: CharacterSet(charactersIn: "_"))
    guard let firstLetter = result.firstIndex(where: { $0.isLetter }) else { return "" }
    return String(result[firstLetter...])
}

func lmlWrapInXml(selectedText: String, actionType: String, comment: String) -> String {
    let escaped = lmlXmlEscape(comment)
    return "<\(actionType) comment=\"\(escaped)\">\(selectedText)</\(actionType)>"
}

func lmlFormatPreview(_ text: String, maxLength: Int = 50) -> String {
    let raw     = text.prefix(maxLength)
    let oneLine = raw.replacingOccurrences(of: "\n", with: " ")
                     .replacingOccurrences(of: "\r", with: " ")
    let suffix  = text.count > maxLength ? "\u{2026}" : ""
    return "\u{201c}\(oneLine)\(suffix)\u{201d}"
}

// ─── Test runner ────────────────────────────────────────────────────────────

var passed = 0
var failed = 0

func assert(_ condition: Bool, _ msg: String, file: String = #file, line: Int = #line) {
    if condition {
        passed += 1
    } else {
        failed += 1
        print("  FAIL (\(file):\(line)): \(msg)")
    }
}

func assertEqual<T: Equatable>(_ a: T, _ b: T, _ label: String = "",
                                file: String = #file, line: Int = #line) {
    if a == b {
        passed += 1
    } else {
        failed += 1
        let tag = label.isEmpty ? "" : " [\(label)]"
        print("  FAIL (\(file):\(line))\(tag): expected \"\(b)\", got \"\(a)\"")
    }
}

func section(_ name: String, _ body: () -> Void) {
    print("▸ \(name)")
    body()
}

// ─── xmlEscape ──────────────────────────────────────────────────────────────

section("xmlEscape") {
    assertEqual(lmlXmlEscape(""), "", "empty")
    assertEqual(lmlXmlEscape("hello world"), "hello world", "no special chars")
    assertEqual(lmlXmlEscape("A & B"), "A &amp; B", "ampersand")
    assertEqual(lmlXmlEscape("say \"hi\""), "say &quot;hi&quot;", "double quote")
    assertEqual(lmlXmlEscape("<b>bold</b>"), "&lt;b&gt;bold&lt;/b&gt;", "angle brackets")
    assertEqual(
        lmlXmlEscape("a & b < c > d \"e\""),
        "a &amp; b &lt; c &gt; d &quot;e&quot;",
        "all special chars"
    )
    assertEqual(lmlXmlEscape("&amp;"), "&amp;amp;", "already escaped gets double-escaped")
}

// ─── sanitizeActionType ─────────────────────────────────────────────────────

section("sanitizeActionType") {
    assertEqual(lmlSanitizeActionType("task"), "task", "valid tag")
    assertEqual(lmlSanitizeActionType("MyTag"), "mytag", "lowercased")
    assertEqual(lmlSanitizeActionType("123abc"), "abc", "leading numbers stripped (must start with letter)")
    assertEqual(lmlSanitizeActionType("@#$tag!"), "tag", "special chars become underscores, trimmed")
    assertEqual(lmlSanitizeActionType("12345"), "", "all numbers -> empty")
    assertEqual(lmlSanitizeActionType(""), "", "empty string")
    assertEqual(lmlSanitizeActionType("my-tag_name"), "my_tag_name", "hyphens become underscores")
    assertEqual(lmlSanitizeActionType("-tag"), "tag", "leading hyphen trimmed")
    assertEqual(lmlSanitizeActionType("_tag"), "tag", "leading underscore trimmed")
    assertEqual(lmlSanitizeActionType("my tag"), "my_tag", "spaces become underscores")
    assertEqual(lmlSanitizeActionType("!@#$%"), "", "only special chars -> empty")
    assertEqual(lmlSanitizeActionType("a1b2"), "a1b2", "numbers after letter kept")
    assertEqual(lmlSanitizeActionType("tag-123"), "tag_123", "hyphens become underscores")
    assertEqual(lmlSanitizeActionType("My  Cool  Tag"), "my_cool_tag", "multiple spaces collapsed")
    assertEqual(lmlSanitizeActionType("ACTION_TYPE"), "action_type", "uppercased with underscore")
}

// ─── wrapInXml ──────────────────────────────────────────────────────────────

section("wrapInXml") {
    assertEqual(
        lmlWrapInXml(selectedText: "hello", actionType: "task", comment: "urgent"),
        "<task comment=\"urgent\">hello</task>",
        "basic wrap"
    )
    assertEqual(
        lmlWrapInXml(selectedText: "text", actionType: "note", comment: ""),
        "<note comment=\"\">text</note>",
        "empty comment"
    )
    assertEqual(
        lmlWrapInXml(selectedText: "x", actionType: "t", comment: "a & \"b\""),
        "<t comment=\"a &amp; &quot;b&quot;\">x</t>",
        "comment with special chars is escaped"
    )
    assertEqual(
        lmlWrapInXml(selectedText: "line1\nline2", actionType: "code", comment: ""),
        "<code comment=\"\">line1\nline2</code>",
        "multiline selected text"
    )
    assertEqual(
        lmlWrapInXml(selectedText: "<div>hi</div>", actionType: "raw", comment: ""),
        "<raw comment=\"\"><div>hi</div></raw>",
        "selected text is NOT escaped"
    )
}

// ─── formatPreview ──────────────────────────────────────────────────────────

section("formatPreview") {
    assertEqual(lmlFormatPreview("hello"), "\u{201c}hello\u{201d}", "short text")

    let fifty = String(repeating: "a", count: 50)
    assertEqual(lmlFormatPreview(fifty), "\u{201c}\(fifty)\u{201d}", "exactly 50 chars")

    let sixty = String(repeating: "a", count: 60)
    assertEqual(lmlFormatPreview(sixty), "\u{201c}\(fifty)\u{2026}\u{201d}", "over 50 truncated")

    assertEqual(
        lmlFormatPreview("line1\nline2\rline3"),
        "\u{201c}line1 line2 line3\u{201d}",
        "newlines replaced"
    )

    assertEqual(lmlFormatPreview(""), "\u{201c}\u{201d}", "empty string")

    assertEqual(
        lmlFormatPreview("abcdefghij", maxLength: 5),
        "\u{201c}abcde\u{2026}\u{201d}",
        "custom max length"
    )
}

// ─── fuzzyMatch ─────────────────────────────────────────────────────────

func lmlFuzzyMatch(query: String, candidate: String) -> Int? {
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
            if ci == qi - 1 { score += 2 }
            lastMatchIdx = ci
        }
    }
    return qi == q.count ? score : nil
}

section("fuzzyMatch") {
    // Empty query matches everything
    assert(lmlFuzzyMatch(query: "", candidate: "anything") != nil, "empty query matches")

    // Exact match
    assert(lmlFuzzyMatch(query: "task", candidate: "task") != nil, "exact match")

    // Prefix match
    assert(lmlFuzzyMatch(query: "ta", candidate: "task") != nil, "prefix match")

    // Substring chars in order
    assert(lmlFuzzyMatch(query: "tk", candidate: "task") != nil, "subsequence match")

    // No match
    assert(lmlFuzzyMatch(query: "xyz", candidate: "task") == nil, "no match returns nil")

    // Case insensitive
    assert(lmlFuzzyMatch(query: "TASK", candidate: "task") != nil, "case insensitive")
    assert(lmlFuzzyMatch(query: "task", candidate: "TASK") != nil, "case insensitive reverse")

    // Prefix match scores higher than late match
    let prefixScore = lmlFuzzyMatch(query: "ta", candidate: "task")!
    let lateScore   = lmlFuzzyMatch(query: "ta", candidate: "xxxta")!
    assert(prefixScore > lateScore, "prefix scores higher than late match")

    // Exact match scores higher than partial
    let exactScore  = lmlFuzzyMatch(query: "task", candidate: "task")!
    let partialScore = lmlFuzzyMatch(query: "task", candidate: "my_task_thing")!
    assert(exactScore > partialScore, "exact scores higher than partial")

    // Consecutive matches score higher
    let consecutiveScore = lmlFuzzyMatch(query: "abc", candidate: "abc_def")!
    let scatteredScore   = lmlFuzzyMatch(query: "abc", candidate: "axbxc")!
    assert(consecutiveScore > scatteredScore, "consecutive scores higher than scattered")

    // Query longer than candidate
    assert(lmlFuzzyMatch(query: "toolong", candidate: "to") == nil, "query longer than candidate")
}

// ─── Summary ────────────────────────────────────────────────────────────────

print("")
if failed == 0 {
    print("All \(passed) tests passed.")
} else {
    print("\(failed) FAILED, \(passed) passed.")
    exit(1)
}
