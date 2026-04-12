import Foundation
import Carbon.HIToolbox

/// Backs the Settings window: displays the current hotkey binding,
/// lets the user record a new one, and persists the change.
@MainActor
public final class SettingsViewModel: ObservableObject {

    @Published public var currentBinding: HotkeyBinding
    @Published public var isRecording: Bool = false

    private let prefs: PreferencesRepositoryProtocol
    private let hotkeyManager: HotkeyManager

    public init(prefs: PreferencesRepositoryProtocol, hotkeyManager: HotkeyManager) {
        self.prefs = prefs
        self.hotkeyManager = hotkeyManager
        self.currentBinding = prefs.loadHotkey()
    }

    public func startRecording() {
        isRecording = true
    }

    /// Called by the key-capture view when the user presses a new combo.
    public func recordBinding(keyCode: UInt32, modifiers: UInt32) {
        let binding = HotkeyBinding(keyCode: keyCode, modifiers: modifiers)
        prefs.saveHotkey(binding)
        hotkeyManager.register(binding)
        currentBinding = binding
        isRecording = false
    }

    public func cancelRecording() {
        isRecording = false
    }

    public func resetToDefault() {
        let binding = HotkeyBinding.default
        prefs.saveHotkey(binding)
        hotkeyManager.register(binding)
        currentBinding = binding
        isRecording = false
    }
}
