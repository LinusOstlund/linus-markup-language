import AppKit

/// Shows a brief floating toast (e.g. "No text selected") centred on screen,
/// then auto-dismisses after 1.5 s. Keeps the same visual style as the
/// original `showBriefAlert` but pulled out of AppDelegate so any service
/// can call it.
public enum NotificationToast {

    @MainActor
    public static func show(_ message: String) {
        let w: CGFloat = 260
        let h: CGFloat = 48

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: w, height: h),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.level = .floating

        let box = NSView(frame: NSRect(x: 0, y: 0, width: w, height: h))
        box.wantsLayer = true
        box.layer?.cornerRadius = 8
        box.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        box.layer?.borderColor = NSColor.separatorColor.cgColor
        box.layer?.borderWidth = 0.5

        let label = NSTextField(labelWithString: message)
        label.frame = NSRect(x: 12, y: 0, width: w - 24, height: h)
        label.alignment = .center
        label.font = .systemFont(ofSize: 13)
        box.addSubview(label)

        window.contentView = box
        window.center()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            window.orderOut(nil)
        }
    }
}
