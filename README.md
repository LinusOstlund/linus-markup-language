# LML — Linus Markup Language

A native macOS menu bar app for wrapping selected text in XML tags, designed for inline editing with LLMs.

## What it does

1. Select text in any app.
2. Press **⌘⌥⌃L** (Cmd + Option + Control + L).
3. A small panel appears asking for an **action type** (the XML tag name) and an optional **comment**.
4. Press **Return** — the selected text is replaced with:

```
<action_type comment="your comment">selected text</action_type>
```

**Example:** Select `"Deploy to staging"`, type `task` / `urgent` → result:

```xml
<task comment="urgent">Deploy to staging</task>
```

## Build

Requires macOS with Xcode Command Line Tools installed (`xcode-select --install`).

```bash
swiftc LML.swift -framework Cocoa -framework Carbon -o LML
```

## Run

```bash
./LML
```

The app runs as a menu bar item (`⟨/⟩`) with no Dock icon.

## Usage

| Action | How |
|---|---|
| Wrap selected text | **⌘⌥⌃L** or click `⟨/⟩` → Wrap Selected Text |
| Re-use a recent tag | Click `⟨/⟩` → Recent Tags → pick one, then trigger wrap |
| Clear recent tags | Click `⟨/⟩` → Clear Recent Tags |
| Quit | Click `⟨/⟩` → Quit |

### Panel shortcuts

| Key | Action |
|---|---|
| **Return** | Confirm (OK) |
| **Escape** | Cancel |
| **Tab** | Move between fields |

## Permissions

On first launch LML will prompt for **Accessibility** access. This is required to simulate Cmd+C / Cmd+V for reading and replacing selected text. Grant it in:

> System Settings → Privacy & Security → Accessibility

Relaunch after granting.

## Customising the hotkey

Open `LML.swift` and change the two constants near the top of the file:

```swift
private let kHotkeyKeycode   = UInt32(37)  // 37 = L; see CGKeyCode for other values
private let kHotkeyModifiers = UInt32(cmdKey | optionKey | controlKey)
```

Common key codes: `A`=0, `S`=1, `D`=2, `F`=3, `H`=4, `G`=5, `Z`=6, `X`=7, `C`=8, `V`=9, `B`=11, `Q`=12, `W`=13, `E`=14, `R`=15, `Y`=16, `T`=17, `1`=18, `2`=19, `3`=20, `4`=21, `6`=22, `5`=23, `=`=24, `9`=25, `7`=26, `-`=27, `8`=28, `0`=29, `]`=30, `O`=31, `U`=32, `[`=33, `I`=34, `P`=35, `Return`=36, `L`=37, `J`=38, `'`=39, `K`=40, `;`=41, `\`=42, `,`=43, `/`=44, `N`=45, `M`=46, `.`=47, `Tab`=48, `Space`=49.

Rebuild after any change:

```bash
swiftc LML.swift -framework Cocoa -framework Carbon -o LML
```
