import AppKit
import Carbon.HIToolbox

/// Owns every side effect that touches the system clipboard or synthesizes
/// keyboard events. The protocol lets `WrapFlowService` be tested against a
/// deterministic in-memory fake.
public protocol ClipboardServicing: AnyObject {
    func read() -> String?
    func write(_ string: String)
    func clear()
    /// Synthesize ⌘C into the currently-focused app.
    func simulateCopy()
    /// Synthesize ⌘V into the currently-focused app.
    func simulatePaste()
}

public final class ClipboardService: ClipboardServicing {

    private let pasteboard: NSPasteboard

    public init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    public func read() -> String? {
        pasteboard.string(forType: .string)
    }

    public func write(_ string: String) {
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }

    public func clear() {
        pasteboard.clearContents()
    }

    public func simulateCopy() {
        post(keyCode: CGKeyCode(kVK_ANSI_C))
    }

    public func simulatePaste() {
        post(keyCode: CGKeyCode(kVK_ANSI_V))
    }

    /// Posts a down+up keyboard event with ⌘ held. Uses
    /// `cgSessionEventTap` so events go to whichever app is frontmost —
    /// not back to us.
    private func post(keyCode: CGKeyCode) {
        let src = CGEventSource(stateID: .hidSystemState)
        let down = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: true)
        let up   = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: false)
        down?.flags = .maskCommand
        up?.flags   = .maskCommand
        down?.post(tap: .cgSessionEventTap)
        up?.post(tap: .cgSessionEventTap)
    }
}
