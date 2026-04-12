import Foundation
import Carbon.HIToolbox

/// A recently-used XML action tag. Thin wrapper that gives us a typed
/// identifier and a place to grow (usage count, last-used date, …) without
/// touching every call site.
public struct Tag: Equatable, Hashable, Codable, Identifiable {
    public let name: String
    public var id: String { name }

    public init(name: String) {
        self.name = name
    }
}

/// A global hotkey binding encoded in Carbon's vocabulary (keycode + modifier
/// mask). Carbon is the only stable public API for registering app-wide
/// hotkeys on macOS, so we stay in its units end-to-end.
public struct HotkeyBinding: Equatable, Codable {
    /// Carbon virtual keycode (e.g. `37` = `L`).
    public var keyCode: UInt32
    /// Carbon modifier mask (e.g. `controlKey | shiftKey`).
    public var modifiers: UInt32

    public init(keyCode: UInt32, modifiers: UInt32) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    public static let `default` = HotkeyBinding(
        keyCode: UInt32(kVK_ANSI_L),
        modifiers: UInt32(controlKey | shiftKey)
    )

    /// Human-readable label like `⌃⇧L` for menu items and settings.
    public var displayString: String {
        var parts = ""
        if modifiers & UInt32(controlKey)  != 0 { parts += "⌃" }
        if modifiers & UInt32(optionKey)   != 0 { parts += "⌥" }
        if modifiers & UInt32(shiftKey)    != 0 { parts += "⇧" }
        if modifiers & UInt32(cmdKey)      != 0 { parts += "⌘" }
        parts += KeyCodeNames.name(for: keyCode)
        return parts
    }
}

/// Maps Carbon virtual keycodes to single-character labels for display.
/// Only covers keys we actually care about; unknown keys fall back to
/// `Key(0x..)` so the UI never shows a blank.
public enum KeyCodeNames {
    public static func name(for keyCode: UInt32) -> String {
        switch Int(keyCode) {
        case kVK_ANSI_A: return "A"
        case kVK_ANSI_B: return "B"
        case kVK_ANSI_C: return "C"
        case kVK_ANSI_D: return "D"
        case kVK_ANSI_E: return "E"
        case kVK_ANSI_F: return "F"
        case kVK_ANSI_G: return "G"
        case kVK_ANSI_H: return "H"
        case kVK_ANSI_I: return "I"
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_O: return "O"
        case kVK_ANSI_P: return "P"
        case kVK_ANSI_Q: return "Q"
        case kVK_ANSI_R: return "R"
        case kVK_ANSI_S: return "S"
        case kVK_ANSI_T: return "T"
        case kVK_ANSI_U: return "U"
        case kVK_ANSI_V: return "V"
        case kVK_ANSI_W: return "W"
        case kVK_ANSI_X: return "X"
        case kVK_ANSI_Y: return "Y"
        case kVK_ANSI_Z: return "Z"
        case kVK_ANSI_0: return "0"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_ANSI_5: return "5"
        case kVK_ANSI_6: return "6"
        case kVK_ANSI_7: return "7"
        case kVK_ANSI_8: return "8"
        case kVK_ANSI_9: return "9"
        case kVK_Space:  return "Space"
        case kVK_Return: return "⏎"
        case kVK_Tab:    return "⇥"
        default:         return String(format: "Key(0x%02X)", keyCode)
        }
    }
}
