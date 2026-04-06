# Claude Code Prompt: XMLWrapper macOS Menu Bar App

Build a native macOS menu bar app in Swift called **XMLWrapper** that wraps selected text in XML tags.

## What it does

1. User selects text in any app
2. User presses a global hotkey (default: **⌘⇧X**)
3. A small popup appears asking for:
   - **Action type** (the XML tag name) — a text field with a dropdown of recently used values
   - **Comment** (the value for the `comment` attribute) — a text field
4. User presses Enter (or clicks OK)
5. The selected text is replaced with: `<action_type comment="their comment">selected text</action_type>`

For example, if the user selects "Deploy to staging", picks action_type `task` and types comment `urgent`, the result is:
```
<task comment="urgent">Deploy to staging</task>
```

## Technical requirements

- **Single-file Swift app** compiled with `swiftc` (no Xcode project needed). Use `-framework Cocoa -framework Carbon`.
- **Menu bar only** — no Dock icon. Use `NSApplication.setActivationPolicy(.accessory)`.
- **Global hotkey** registered via Carbon `RegisterEventHotKey` (Cmd+Shift+X, keycode 7).
- **Accessibility permission** — prompt on first launch with `AXIsProcessTrustedWithOptions`. Show a helpful alert if not granted.

## The popup/input panel

When the hotkey is pressed:

1. Simulate ⌘C to copy the selected text to clipboard.
2. Show a small floating **NSPanel** (or NSWindow with `.utility` style mask) near the center of the screen.
3. The panel has:
   - A label showing a preview of the selected text (truncated to ~50 chars).
   - A **combo box** (NSComboBox) for action_type — editable, with a dropdown of the 10 most recently used action types. Placeholder: `"action_type"`.
   - A **text field** for comment. Placeholder: `"comment"`.
   - OK and Cancel buttons. Enter key triggers OK, Escape triggers Cancel.
4. Focus should land on the action_type combo box immediately.
5. On OK:
   - Construct `<action_type comment="comment">selected text</action_type>`
   - Put it on the clipboard
   - Simulate ⌘V to paste
   - Close the panel
   - Save the action_type to recent history (UserDefaults, max 10, most recent first, no duplicates)
6. On Cancel: close the panel, restore original clipboard, do nothing.

## Menu bar icon and menu

- Status item title: `⟨/⟩`
- Menu items:
  - "Wrap Selected Text (⌘⇧X)" — triggers the wrap flow
  - Separator
  - "Recent Tags" → submenu listing recent action_types, clicking one pre-fills it next time
  - "Clear Recent Tags" — clears the history
  - Separator
  - "Quit" (⌘Q)

## Clipboard handling

- Before simulating ⌘C, save the current clipboard contents.
- After the paste is done (200ms delay), restore the original clipboard.
- Use `CGEvent` for simulating keystrokes with proper key-down/key-up and modifier flags.

## Edge cases

- If no text is selected (clipboard is empty after ⌘C), show a brief "No text selected" message in the panel and close after 1.5s.
- Escape any `"` in the comment value to `&quot;` and `<`/`>` in the comment to `&lt;`/`&gt;`.
- If the action_type contains spaces or invalid XML tag characters, strip/replace them (keep only `[a-zA-Z0-9_-]`, must start with a letter).

## Code style

- Well-organized with `// MARK: -` sections
- Comments on non-obvious logic
- All UI built programmatically (no storyboards/nibs)
- Store all UserDefaults keys as constants

## Deliverables

1. `XMLWrapper.swift` — the complete app in one file
2. `README.md` — with build command, usage instructions, and how to customize the hotkey
