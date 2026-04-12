import Foundation
import LMLCore

// MARK: - Minimal test harness

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

// MARK: - XMLWrapper

section("XMLWrapper.escape") {
    assertEqual(XMLWrapper.escape(""), "", "empty")
    assertEqual(XMLWrapper.escape("hello world"), "hello world", "no special chars")
    assertEqual(XMLWrapper.escape("A & B"), "A &amp; B", "ampersand")
    assertEqual(XMLWrapper.escape("say \"hi\""), "say &quot;hi&quot;", "double quote")
    assertEqual(XMLWrapper.escape("<b>bold</b>"), "&lt;b&gt;bold&lt;/b&gt;", "angle brackets")
    assertEqual(
        XMLWrapper.escape("a & b < c > d \"e\""),
        "a &amp; b &lt; c &gt; d &quot;e&quot;",
        "all special chars"
    )
    assertEqual(XMLWrapper.escape("&amp;"), "&amp;amp;", "already escaped gets double-escaped")
}

section("XMLWrapper.wrap") {
    assertEqual(
        XMLWrapper.wrap(selectedText: "hello", actionType: "task", comment: "urgent"),
        "<task comment=\"urgent\">hello</task>",
        "basic wrap"
    )
    assertEqual(
        XMLWrapper.wrap(selectedText: "text", actionType: "note", comment: ""),
        "<note comment=\"\">text</note>",
        "empty comment"
    )
    assertEqual(
        XMLWrapper.wrap(selectedText: "x", actionType: "t", comment: "a & \"b\""),
        "<t comment=\"a &amp; &quot;b&quot;\">x</t>",
        "comment with special chars is escaped"
    )
    assertEqual(
        XMLWrapper.wrap(selectedText: "line1\nline2", actionType: "code", comment: ""),
        "<code comment=\"\">line1\nline2</code>",
        "multiline selected text"
    )
    assertEqual(
        XMLWrapper.wrap(selectedText: "<div>hi</div>", actionType: "raw", comment: ""),
        "<raw comment=\"\"><div>hi</div></raw>",
        "selected text is NOT escaped"
    )
}

// MARK: - Sanitizer

section("Sanitizer") {
    assertEqual(Sanitizer.sanitizeActionType("task"), "task", "valid tag")
    assertEqual(Sanitizer.sanitizeActionType("MyTag"), "mytag", "lowercased")
    assertEqual(Sanitizer.sanitizeActionType("123abc"), "abc", "leading numbers stripped")
    assertEqual(Sanitizer.sanitizeActionType("@#$tag!"), "tag", "special chars")
    assertEqual(Sanitizer.sanitizeActionType("12345"), "", "all numbers -> empty")
    assertEqual(Sanitizer.sanitizeActionType(""), "", "empty string")
    assertEqual(Sanitizer.sanitizeActionType("my-tag_name"), "my_tag_name", "hyphens -> underscores")
    assertEqual(Sanitizer.sanitizeActionType("-tag"), "tag", "leading hyphen trimmed")
    assertEqual(Sanitizer.sanitizeActionType("_tag"), "tag", "leading underscore trimmed")
    assertEqual(Sanitizer.sanitizeActionType("my tag"), "my_tag", "spaces -> underscores")
    assertEqual(Sanitizer.sanitizeActionType("!@#$%"), "", "only special chars -> empty")
    assertEqual(Sanitizer.sanitizeActionType("a1b2"), "a1b2", "numbers after letter kept")
    assertEqual(Sanitizer.sanitizeActionType("tag-123"), "tag_123", "hyphens with numbers")
    assertEqual(Sanitizer.sanitizeActionType("My  Cool  Tag"), "my_cool_tag", "multiple spaces collapsed")
    assertEqual(Sanitizer.sanitizeActionType("ACTION_TYPE"), "action_type", "uppercased with underscore")
}

// MARK: - FuzzyMatcher

section("FuzzyMatcher.match") {
    assert(FuzzyMatcher.match(query: "", candidate: "anything") != nil, "empty query matches")
    assert(FuzzyMatcher.match(query: "task", candidate: "task") != nil, "exact match")
    assert(FuzzyMatcher.match(query: "ta", candidate: "task") != nil, "prefix match")
    assert(FuzzyMatcher.match(query: "tk", candidate: "task") != nil, "subsequence match")
    assert(FuzzyMatcher.match(query: "xyz", candidate: "task") == nil, "no match returns nil")
    assert(FuzzyMatcher.match(query: "TASK", candidate: "task") != nil, "case insensitive")
    assert(FuzzyMatcher.match(query: "task", candidate: "TASK") != nil, "case insensitive reverse")

    let prefixScore = FuzzyMatcher.match(query: "ta", candidate: "task")!
    let lateScore   = FuzzyMatcher.match(query: "ta", candidate: "xxxta")!
    assert(prefixScore > lateScore, "prefix scores higher than late match")

    let exactScore   = FuzzyMatcher.match(query: "task", candidate: "task")!
    let partialScore = FuzzyMatcher.match(query: "task", candidate: "my_task_thing")!
    assert(exactScore > partialScore, "exact scores higher than partial")

    let consecutiveScore = FuzzyMatcher.match(query: "abc", candidate: "abc_def")!
    let scatteredScore   = FuzzyMatcher.match(query: "abc", candidate: "axbxc")!
    assert(consecutiveScore > scatteredScore, "consecutive scores higher than scattered")

    assert(FuzzyMatcher.match(query: "toolong", candidate: "to") == nil, "query longer than candidate")
}

section("FuzzyMatcher.rank") {
    let result = FuzzyMatcher.rank(query: "ta", candidates: ["my_task_thing", "task", "xxxta"])
    assertEqual(result.first ?? "", "task", "best match first")

    let noMatch = FuzzyMatcher.rank(query: "xyz", candidates: ["task", "note"])
    assert(noMatch.isEmpty, "no matches filtered out")
}

// MARK: - Preview

section("Preview") {
    assertEqual(Preview.format("hello"), "\u{201c}hello\u{201d}", "short text")

    let fifty = String(repeating: "a", count: 50)
    assertEqual(Preview.format(fifty), "\u{201c}\(fifty)\u{201d}", "exactly 50 chars")

    let sixty = String(repeating: "a", count: 60)
    assertEqual(Preview.format(sixty), "\u{201c}\(fifty)\u{2026}\u{201d}", "over 50 truncated")

    assertEqual(
        Preview.format("line1\nline2\rline3"),
        "\u{201c}line1 line2 line3\u{201d}",
        "newlines replaced"
    )

    assertEqual(Preview.format(""), "\u{201c}\u{201d}", "empty string")

    assertEqual(
        Preview.format("abcdefghij", maxLength: 5),
        "\u{201c}abcde\u{2026}\u{201d}",
        "custom max length"
    )
}

// MARK: - TagRepository

section("TagRepository") {
    let defaults = UserDefaults(suiteName: "LMLTests.\(UUID().uuidString)")!
    let repo = TagRepository(defaults: defaults, key: "testRecentTags", maxCount: 3)

    assert(repo.loadRecent().isEmpty, "empty by default")

    repo.record(Tag(name: "task"))
    assertEqual(repo.loadRecent().map(\.name), ["task"], "record and load")

    repo.record(Tag(name: "a"))
    repo.record(Tag(name: "b"))
    assertEqual(repo.loadRecent().map(\.name), ["b", "a", "task"], "most recent first")

    repo.record(Tag(name: "a"))
    assertEqual(repo.loadRecent().map(\.name), ["a", "b", "task"], "duplicate moves to front")

    repo.record(Tag(name: "d"))
    assertEqual(repo.loadRecent().map(\.name), ["d", "a", "b"], "max count trims tail")

    repo.clear()
    assert(repo.loadRecent().isEmpty, "clear empties list")
}

// MARK: - Summary

print("")
if failed == 0 {
    print("All \(passed) tests passed.")
} else {
    print("\(failed) FAILED, \(passed) passed.")
    exit(1)
}
