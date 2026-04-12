import SwiftUI
import Carbon.HIToolbox

/// Settings window accessible via the menu bar. Currently just hotkey
/// rebinding; easy to grow with more sections later.
public struct SettingsView: View {

    @ObservedObject public var viewModel: SettingsViewModel

    public init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Form {
            Section("Hotkey") {
                HStack {
                    Text("Trigger shortcut")

                    Spacer()

                    if viewModel.isRecording {
                        HotkeyRecorderView { keyCode, modifiers in
                            viewModel.recordBinding(keyCode: keyCode, modifiers: modifiers)
                        }
                        .frame(width: 140, height: 24)

                        Button("Cancel") { viewModel.cancelRecording() }
                    } else {
                        Text(viewModel.currentBinding.displayString)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.quaternary)
                            .clipShape(RoundedRectangle(cornerRadius: 4))

                        Button("Change…") { viewModel.startRecording() }
                    }
                }

                HStack {
                    Spacer()
                    Button("Reset to Default") { viewModel.resetToDefault() }
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 160)
    }
}

// MARK: - Hotkey Recorder

/// An AppKit NSView wrapped for SwiftUI that captures the next key-down
/// event and reports its keyCode + Carbon modifier mask.
public struct HotkeyRecorderView: NSViewRepresentable {

    public let onRecord: (_ keyCode: UInt32, _ modifiers: UInt32) -> Void

    public init(onRecord: @escaping (_ keyCode: UInt32, _ modifiers: UInt32) -> Void) {
        self.onRecord = onRecord
    }

    public func makeNSView(context: Context) -> HotkeyRecorderNSView {
        let view = HotkeyRecorderNSView()
        view.onRecord = onRecord
        return view
    }

    public func updateNSView(_ nsView: HotkeyRecorderNSView, context: Context) {}
}

public final class HotkeyRecorderNSView: NSView {

    public var onRecord: ((_ keyCode: UInt32, _ modifiers: UInt32) -> Void)?

    override public var acceptsFirstResponder: Bool { true }

    override public func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override public func draw(_ dirtyRect: NSRect) {
        NSColor.controlAccentColor.withAlphaComponent(0.15).setFill()
        let path = NSBezierPath(roundedRect: bounds, xRadius: 4, yRadius: 4)
        path.fill()

        let text = "Press shortcut…" as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        let size = text.size(withAttributes: attrs)
        let point = NSPoint(
            x: (bounds.width - size.width) / 2,
            y: (bounds.height - size.height) / 2
        )
        text.draw(at: point, withAttributes: attrs)
    }

    override public func keyDown(with event: NSEvent) {
        // Convert Cocoa modifier flags to Carbon modifier mask
        var carbonMods: UInt32 = 0
        let flags = event.modifierFlags
        if flags.contains(.control) { carbonMods |= UInt32(controlKey) }
        if flags.contains(.option)  { carbonMods |= UInt32(optionKey) }
        if flags.contains(.shift)   { carbonMods |= UInt32(shiftKey) }
        if flags.contains(.command) { carbonMods |= UInt32(cmdKey) }

        // Require at least one modifier so bare keys don't hijack typing.
        guard carbonMods != 0 else { return }

        onRecord?(UInt32(event.keyCode), carbonMods)
    }
}
