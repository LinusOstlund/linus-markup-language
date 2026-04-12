import AppKit

/// Checks whether this process has Accessibility access and, if not, presents
/// a one-time alert directing the user to System Settings.
public enum AccessibilityGuard {

    /// Returns `true` when the app already has accessibility access.
    /// When it doesn't, it triggers the system prompt and optionally
    /// shows a helper alert after a short delay so the menu bar icon is
    /// visible first.
    @discardableResult
    public static func ensureAccess(showAlert: Bool = true) -> Bool {
        let opts = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary

        if AXIsProcessTrustedWithOptions(opts) { return true }

        if showAlert {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showAccessibilityAlert()
            }
        }
        return false
    }

    private static func showAccessibilityAlert() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = """
            LML needs Accessibility access to read and replace selected text.

            Please grant access in System Settings → Privacy & Security → \
            Accessibility, then relaunch the app.
            """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")
        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string:
                "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
            ) {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
