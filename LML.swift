import Cocoa
import Carbon

// MARK: - Constants

private let kRecentTagsKey   = "recentActionTypes"
private let kMaxRecentTags   = 10
private let kHotkeyKeycode   = UInt32(37)  // L
// Cmd + Option + Control
private let kHotkeyModifiers = UInt32(cmdKey | optionKey | controlKey)

// MARK: - Carbon Hotkey Callback

// Must be a free function (not a closure) to serve as a C function pointer.
private func hotkeyEventHandler(
    nextHandler: EventHandlerCallRef?,
    event: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let userData = userData else { return OSStatus(eventNotHandledErr) }
    let delegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()

    var hotkeyID = EventHotKeyID()
    GetEventParameter(
        event,
        UInt32(kEventParamDirectObject),
        typeEventHotKeyID,
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotkeyID
    )

    if hotkeyID.id == 1 {
        DispatchQueue.main.async { delegate.wrapSelectedText() }
    }
    return noErr
}

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var recentTagsMenu: NSMenu!
    private var hotKeyRef: EventHotKeyRef?
    private var activePanel: InputPanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        checkAccessibility()
        setupMenuBar()
        registerHotKey()
    }

    // MARK: - Accessibility

    private func checkAccessibility() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        guard !AXIsProcessTrustedWithOptions(opts) else { return }

        // Show guidance after a short delay so the app is visible in the menu bar first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
                let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                NSWorkspace.shared.open(url)
            }
        }
    }

    // MARK: - Menu Bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let btn = statusItem.button {
            btn.title = "⟨/⟩"
            btn.font  = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        }
        statusItem.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let wrapItem = NSMenuItem(
            title: "Wrap Selected Text  ⌘⌥⌃L",
            action: #selector(wrapSelectedText),
            keyEquivalent: ""
        )
        wrapItem.target = self
        menu.addItem(wrapItem)

        menu.addItem(.separator())

        let recentItem = NSMenuItem(title: "Recent Tags", action: nil, keyEquivalent: "")
        recentTagsMenu = NSMenu()
        recentItem.submenu = recentTagsMenu
        menu.addItem(recentItem)

        let clearItem = NSMenuItem(
            title: "Clear Recent Tags",
            action: #selector(clearRecentTagsAction),
            keyEquivalent: ""
        )
        clearItem.target = self
        menu.addItem(clearItem)

        menu.addItem(.separator())

        menu.addItem(NSMenuItem(
            title: "Quit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        updateRecentTagsMenu()
        return menu
    }

    func updateRecentTagsMenu() {
        recentTagsMenu.removeAllItems()
        let tags = loadRecentTags()
        if tags.isEmpty {
            let empty = NSMenuItem(title: "(none)", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            recentTagsMenu.addItem(empty)
        } else {
            for tag in tags {
                let item = NSMenuItem(title: tag, action: #selector(recentTagSelected(_:)), keyEquivalent: "")
                item.target = self
                recentTagsMenu.addItem(item)
            }
        }
    }

    @objc private func recentTagSelected(_ sender: NSMenuItem) {
        showInputPanel(prefilledTag: sender.title)
    }

    @objc private func clearRecentTagsAction() {
        UserDefaults.standard.removeObject(forKey: kRecentTagsKey)
        updateRecentTagsMenu()
    }

    // MARK: - Hotkey Registration

    private func registerHotKey() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind:  UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            hotkeyEventHandler,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            nil
        )

        var hotkeyID = EventHotKeyID(signature: 0x4C4D4C21, id: 1)  // 'LML!'
        RegisterEventHotKey(kHotkeyKeycode, kHotkeyModifiers, hotkeyID,
                            GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    // MARK: - Wrap Flow

    @objc func wrapSelectedText() {
        showInputPanel(prefilledTag: nil)
    }

    private func showInputPanel(prefilledTag: String?) {
        let pasteboard  = NSPasteboard.general
        let savedString = pasteboard.string(forType: .string)  // save original clipboard

        // Simulate Cmd+C while the previous app is still focused
        pasteboard.clearContents()
        simulateCopy()

        // Wait for the clipboard to be populated
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let selectedText = pasteboard.string(forType: .string) ?? ""

            if selectedText.isEmpty {
                self.showBriefAlert("No text selected")
                self.restoreClipboard(savedString)
                return
            }

            NSApp.activate(ignoringOtherApps: true)

            let panel = InputPanelController(
                selectedText: selectedText,
                prefilledTag: prefilledTag,
                recentTags:   self.loadRecentTags(),
                onOK: { [weak self] actionType, comment in
                    guard let self = self else { return }
                    let escaped = self.xmlEscape(comment)
                    let xml     = "<\(actionType) comment=\"\(escaped)\">\(selectedText)</\(actionType)>"

                    pasteboard.clearContents()
                    pasteboard.setString(xml, forType: .string)
                    self.simulatePaste()

                    // Restore original clipboard after the paste has been processed
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.restoreClipboard(savedString)
                    }

                    self.saveTag(actionType)
                    self.updateRecentTagsMenu()
                    self.activePanel = nil
                },
                onCancel: { [weak self] in
                    self?.restoreClipboard(savedString)
                    self?.activePanel = nil
                }
            )
            panel.showPanel()
            self.activePanel = panel
        }
    }

    // MARK: - Brief Alert

    private func showBriefAlert(_ message: String) {
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 48),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        w.backgroundColor = .clear
        w.isOpaque        = false
        w.hasShadow       = true
        w.level           = .floating

        let box = NSView(frame: NSRect(x: 0, y: 0, width: 260, height: 48))
        box.wantsLayer = true
        box.layer?.cornerRadius       = 8
        box.layer?.backgroundColor    = NSColor.windowBackgroundColor.cgColor
        box.layer?.borderColor        = NSColor.separatorColor.cgColor
        box.layer?.borderWidth        = 0.5

        let label = NSTextField(labelWithString: message)
        label.frame     = NSRect(x: 12, y: 0, width: 236, height: 48)
        label.alignment = .center
        label.font      = NSFont.systemFont(ofSize: 13)
        box.addSubview(label)

        w.contentView = box
        w.center()
        NSApp.activate(ignoringOtherApps: true)
        w.makeKeyAndOrderFront(nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { w.orderOut(nil) }
    }

    // MARK: - XML Helpers

    private func xmlEscape(_ str: String) -> String {
        str
            .replacingOccurrences(of: "&",  with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "<",  with: "&lt;")
            .replacingOccurrences(of: ">",  with: "&gt;")
    }

    // MARK: - UserDefaults Helpers

    private func loadRecentTags() -> [String] {
        UserDefaults.standard.stringArray(forKey: kRecentTagsKey) ?? []
    }

    private func saveTag(_ tag: String) {
        var tags = loadRecentTags()
        tags.removeAll { $0 == tag }
        tags.insert(tag, at: 0)
        if tags.count > kMaxRecentTags { tags = Array(tags.prefix(kMaxRecentTags)) }
        UserDefaults.standard.set(tags, forKey: kRecentTagsKey)
    }

    private func restoreClipboard(_ savedString: String?) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        if let str = savedString {
            pasteboard.setString(str, forType: .string)
        }
    }

    // MARK: - CGEvent Helpers

    private func simulateCopy() {
        let src  = CGEventSource(stateID: .hidSystemState)
        let down = CGEvent(keyboardEventSource: src, virtualKey: 8, keyDown: true)   // C
        let up   = CGEvent(keyboardEventSource: src, virtualKey: 8, keyDown: false)
        down?.flags = .maskCommand
        up?.flags   = .maskCommand
        down?.post(tap: .cgSessionEventTap)
        up?.post(tap: .cgSessionEventTap)
    }

    private func simulatePaste() {
        let src  = CGEventSource(stateID: .hidSystemState)
        let down = CGEvent(keyboardEventSource: src, virtualKey: 9, keyDown: true)   // V
        let up   = CGEvent(keyboardEventSource: src, virtualKey: 9, keyDown: false)
        down?.flags = .maskCommand
        up?.flags   = .maskCommand
        down?.post(tap: .cgSessionEventTap)
        up?.post(tap: .cgSessionEventTap)
    }
}

// MARK: - InputPanelController

class InputPanelController: NSObject, NSWindowDelegate {

    private var panel: NSPanel!
    private var comboBox: NSComboBox!
    private var commentField: NSTextField!
    private var didComplete = false

    private let selectedText: String
    private let prefilledTag: String?
    private let recentTags:   [String]
    private let onOK:         (String, String) -> Void
    private let onCancel:     () -> Void

    init(
        selectedText: String,
        prefilledTag: String?,
        recentTags:   [String],
        onOK:         @escaping (String, String) -> Void,
        onCancel:     @escaping () -> Void
    ) {
        self.selectedText = selectedText
        self.prefilledTag = prefilledTag
        self.recentTags   = recentTags
        self.onOK         = onOK
        self.onCancel     = onCancel
    }

    func showPanel() {
        let w: CGFloat = 380
        let h: CGFloat = 224

        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: w, height: h),
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title  = "LML"
        panel.level  = .floating
        panel.center()
        panel.delegate = self

        buildUI(in: panel.contentView!, width: w, height: h)

        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(comboBox)
    }

    // MARK: - UI Construction

    private func buildUI(in view: NSView, width w: CGFloat, height h: CGFloat) {
        let p = CGFloat(16)
        let fw = w - 2 * p  // full-width field

        // Layout coordinates (AppKit: y = 0 at bottom)
        let btnH:           CGFloat = 28
        let btnW:           CGFloat = 80
        let btnY:           CGFloat = p
        let commentFieldH:  CGFloat = 22
        let commentFieldY:  CGFloat = btnY + btnH + 14
        let commentLabelH:  CGFloat = 17
        let commentLabelY:  CGFloat = commentFieldY + commentFieldH + 4
        let comboH:         CGFloat = 26
        let comboY:         CGFloat = commentLabelY + commentLabelH + 4
        let tagLabelH:      CGFloat = 17
        let tagLabelY:      CGFloat = comboY + comboH + 4
        let previewY:       CGFloat = tagLabelY + tagLabelH + 8

        // Preview of selected text
        let raw     = selectedText.prefix(50)
        let oneLine = raw.replacingOccurrences(of: "\n", with: " ")
                         .replacingOccurrences(of: "\r", with: " ")
        let suffix  = selectedText.count > 50 ? "…" : ""
        let previewLabel = NSTextField(labelWithString: ""\(oneLine)\(suffix)"")
        previewLabel.frame           = NSRect(x: p, y: previewY, width: fw, height: h - previewY - p)
        previewLabel.font            = NSFont.systemFont(ofSize: 11)
        previewLabel.textColor       = .secondaryLabelColor
        previewLabel.lineBreakMode   = .byTruncatingTail
        previewLabel.maximumNumberOfLines = 1
        view.addSubview(previewLabel)

        // "Action type" label + combo box
        let tagLabel = NSTextField(labelWithString: "Action type")
        tagLabel.frame = NSRect(x: p, y: tagLabelY, width: fw, height: tagLabelH)
        tagLabel.font  = NSFont.systemFont(ofSize: 12, weight: .medium)
        view.addSubview(tagLabel)

        comboBox = NSComboBox()
        comboBox.frame              = NSRect(x: p, y: comboY, width: fw, height: comboH)
        comboBox.placeholderString  = "action_type"
        comboBox.addItems(withObjectValues: recentTags)
        comboBox.numberOfVisibleItems = min(max(recentTags.count, 1), 10)
        if let tag = prefilledTag { comboBox.stringValue = tag }
        view.addSubview(comboBox)

        // "Comment" label + text field
        let commentLabel = NSTextField(labelWithString: "Comment")
        commentLabel.frame = NSRect(x: p, y: commentLabelY, width: fw, height: commentLabelH)
        commentLabel.font  = NSFont.systemFont(ofSize: 12, weight: .medium)
        view.addSubview(commentLabel)

        commentField = NSTextField()
        commentField.frame             = NSRect(x: p, y: commentFieldY, width: fw, height: commentFieldH)
        commentField.placeholderString = "comment"
        view.addSubview(commentField)

        // Cancel button (Escape)
        let cancelBtn = NSButton(title: "Cancel", target: self, action: #selector(cancelPressed))
        cancelBtn.frame        = NSRect(x: w - p - btnW * 2 - 8, y: btnY, width: btnW, height: btnH)
        cancelBtn.keyEquivalent = "\u{1b}"
        view.addSubview(cancelBtn)

        // OK button (Return)
        let okBtn = NSButton(title: "OK", target: self, action: #selector(okPressed))
        okBtn.frame         = NSRect(x: w - p - btnW, y: btnY, width: btnW, height: btnH)
        okBtn.keyEquivalent = "\r"
        okBtn.bezelStyle    = .rounded
        view.addSubview(okBtn)
    }

    // MARK: - Actions

    @objc private func okPressed() {
        let raw       = comboBox.stringValue.trimmingCharacters(in: .whitespaces)
        let sanitized = sanitizeActionType(raw)

        guard !sanitized.isEmpty else {
            shakePanel()
            return
        }

        let comment = commentField.stringValue
        didComplete = true
        panel.orderOut(nil)

        // Brief pause so the previous app can regain focus before we paste
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            self.onOK(sanitized, comment)
        }
    }

    @objc private func cancelPressed() {
        didComplete = true
        panel.orderOut(nil)
        onCancel()
    }

    func windowWillClose(_ notification: Notification) {
        // Handle the X button; avoid double-firing if OK/Cancel already called
        if !didComplete {
            didComplete = true
            onCancel()
        }
    }

    // MARK: - Helpers

    /// Keeps only [a-zA-Z0-9_-] and ensures the result starts with a letter.
    private func sanitizeActionType(_ raw: String) -> String {
        let filtered = raw.filter { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }
        guard let firstLetter = filtered.firstIndex(where: { $0.isLetter }) else { return "" }
        return String(filtered[firstLetter...])
    }

    private func shakePanel() {
        let origin   = panel.frame
        let distance = CGFloat(6)
        let step     = 0.05
        for i in 0..<6 {
            DispatchQueue.main.asyncAfter(deadline: .now() + step * Double(i)) {
                var f = origin
                f.origin.x += (i % 2 == 0) ? distance : -distance
                self.panel.setFrame(f, display: true)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + step * 6) {
            self.panel.setFrame(origin, display: true)
        }
    }
}

// MARK: - Entry Point

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
