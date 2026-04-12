import Foundation

/// Escapes the five XML special characters we care about for attribute values.
/// Order matters: `&` must be replaced first so later replacements don't
/// double-escape the ampersands we introduce.
public enum XMLWrapper {

    public static func escape(_ str: String) -> String {
        str
            .replacingOccurrences(of: "&",  with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "<",  with: "&lt;")
            .replacingOccurrences(of: ">",  with: "&gt;")
    }

    /// Builds `<actionType comment="escaped">selectedText</actionType>`.
    /// `selectedText` is intentionally NOT escaped so code blocks, markdown
    /// and existing XML inside the selection round-trip verbatim.
    public static func wrap(selectedText: String, actionType: String, comment: String) -> String {
        let escapedComment = escape(comment)
        return "<\(actionType) comment=\"\(escapedComment)\">\(selectedText)</\(actionType)>"
    }
}
