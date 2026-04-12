import AppKit
import SwiftUI

/// Bridges the SwiftUI `InputPanelView` into a floating `NSPanel` so it
/// gets proper key-window behaviour without showing in the Dock.
///
/// The `present(…)` method returns an async result — the caller
/// `await`s it, and the panel dismisses itself on OK/Cancel.
@MainActor
public final class InputPanelPresenter {

    private var panel: NSPanel?

    public init() {}

    /// Shows the input panel and suspends until the user confirms or cancels.
    /// Returns `(actionType, comment)` on confirm, or `nil` on cancel.
    public func present(
        selectedText: String,
        prefilledTag: String?,
        recentTags: [String]
    ) async -> (String, String)? {
        return await withCheckedContinuation { continuation in
            var resumed = false

            let vm = InputPanelViewModel(
                selectedText: selectedText,
                prefilledTag: prefilledTag,
                recentTags: recentTags,
                onOK: { [weak self] actionType, comment in
                    guard !resumed else { return }
                    resumed = true
                    self?.dismiss()
                    continuation.resume(returning: (actionType, comment))
                },
                onCancel: { [weak self] in
                    guard !resumed else { return }
                    resumed = true
                    self?.dismiss()
                    continuation.resume(returning: nil)
                }
            )

            let hostingView = NSHostingView(rootView: InputPanelView(viewModel: vm))
            let size = hostingView.intrinsicContentSize

            let p = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: size.width, height: size.height),
                styleMask: [.titled, .closable, .utilityWindow],
                backing: .buffered,
                defer: false
            )
            p.title = "LML"
            p.level = .floating
            p.contentView = hostingView
            p.center()
            p.isReleasedWhenClosed = false

            // If the user closes via the title-bar X, treat it as cancel.
            NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: p,
                queue: .main
            ) { _ in
                guard !resumed else { return }
                resumed = true
                continuation.resume(returning: nil)
            }

            self.panel = p
            p.makeKeyAndOrderFront(nil)
        }
    }

    public func dismiss() {
        panel?.orderOut(nil)
        panel = nil
    }
}
