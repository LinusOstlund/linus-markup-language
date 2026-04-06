# LML — Project Context

## What this is

LML (Linus Markup Language) is a native macOS menu bar app that wraps selected text in XML tags, designed for inline editing with LLMs.

**App name:** LML — never "XMLWrapper" (that's just the name of the spec doc in `docs/`).

## Current state

Initial implementation is complete and live at:
**https://github.com/LinusOstlund/linus-markup-language** (private)

## What was built

- `LML.swift` — single-file Swift app (Cocoa + Carbon), no Xcode project needed
- `README.md` — build instructions and hotkey customisation guide

## Key implementation details

- **Hotkey:** ⌘⌥⌃L (Cmd + Option + Control + L), keycode 37
- **Menu bar icon:** `⟨/⟩`
- **Flow:** Simulate Cmd+C while previous app is still focused → wait 150ms → show NSPanel → on OK wait 120ms for focus to return → simulate Cmd+V
- **Recent tags:** saved to UserDefaults key `recentActionTypes`, max 10, most recent first
- **XML format:** `<action_type comment="escaped comment">selected text</action_type>`
- **Sanitisation:** action_type stripped to `[a-zA-Z0-9_-]`, must start with a letter
- **XML escaping:** `&` `"` `<` `>` escaped in comment value

## Build

```bash
swiftc LML.swift -framework Cocoa -framework Carbon -o LML
./LML
```

Requires macOS with Xcode Command Line Tools (`xcode-select --install`). Grant Accessibility permission on first launch.

## Sandbox note

The development sandbox is ephemeral — always clone from GitHub when starting a new session.
