import AppKit

/// Orchestrates the full wrap-selected-text flow:
///
///     copy → read clipboard → show panel → user confirms →
///     write wrapped XML → paste → restore original clipboard
///
/// All timing-sensitive waits are expressed as `Task.sleep` so the flow
/// reads linearly instead of nesting three levels of `asyncAfter`.
@MainActor
public final class WrapFlowService {

    private let clipboard: ClipboardServicing
    private let tags: TagRepositoryProtocol

    /// Called when the service needs the user to fill in an action type.
    /// The closure receives the selected text and a prefilled tag (or nil),
    /// and returns `(actionType, comment)` — or nil if the user cancelled.
    public var presentPanel: ((_ selectedText: String, _ prefilledTag: String?) async -> (String, String)?)?

    /// Called when there is nothing to wrap (empty selection).
    public var showNotification: ((_ message: String) -> Void)?

    public init(clipboard: ClipboardServicing, tags: TagRepositoryProtocol) {
        self.clipboard = clipboard
        self.tags = tags
    }

    public func run(prefilledTag: String? = nil) {
        Task { @MainActor in
            await execute(prefilledTag: prefilledTag)
        }
    }

    private func execute(prefilledTag: String?) async {
        let savedClipboard = clipboard.read()

        // 1. Simulate ⌘C in the frontmost app
        clipboard.clear()
        clipboard.simulateCopy()

        // 2. Wait for the clipboard to populate
        try? await Task.sleep(for: .milliseconds(150))
        let selectedText = clipboard.read() ?? ""

        guard !selectedText.isEmpty else {
            showNotification?("No text selected")
            restore(savedClipboard)
            return
        }

        // 3. Bring ourselves to front and show the input panel
        NSApp.activate(ignoringOtherApps: true)

        guard let (actionType, comment) = await presentPanel?(selectedText, prefilledTag) else {
            // User cancelled
            restore(savedClipboard)
            return
        }

        // 4. Wrap the text and paste it back
        let xml = XMLWrapper.wrap(
            selectedText: selectedText,
            actionType: actionType,
            comment: comment
        )
        clipboard.write(xml)
        clipboard.simulatePaste()

        // 5. Wait for the paste to land, then restore the original clipboard
        try? await Task.sleep(for: .milliseconds(300))
        restore(savedClipboard)

        // 6. Record the tag for the recent-tags menu
        tags.record(Tag(name: actionType))
    }

    private func restore(_ saved: String?) {
        if let saved {
            clipboard.write(saved)
        } else {
            clipboard.clear()
        }
    }
}
