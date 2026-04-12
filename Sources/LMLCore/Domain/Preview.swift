import Foundation

/// Formats a snippet of selected text for display above the input fields.
/// Collapses newlines to spaces, truncates to `maxLength` chars, and wraps
/// in curly quotes.
public enum Preview {

    public static func format(_ text: String, maxLength: Int = 50) -> String {
        let raw = text.prefix(maxLength)
        let oneLine = raw
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
        let suffix = text.count > maxLength ? "\u{2026}" : ""
        return "\u{201c}\(oneLine)\(suffix)\u{201d}"
    }
}
