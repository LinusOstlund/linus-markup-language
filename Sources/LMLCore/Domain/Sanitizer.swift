import Foundation

/// Turns arbitrary user input into a valid XML tag name.
///
/// Rules:
/// - Lowercased
/// - Only `[a-z0-9_]` survives; everything else becomes `_`
/// - Consecutive underscores collapse to one
/// - Leading/trailing underscores are trimmed
/// - Must start with a letter — leading digits are dropped
/// - Returns `""` if nothing valid remains
public enum Sanitizer {

    public static func sanitizeActionType(_ raw: String) -> String {
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
}
