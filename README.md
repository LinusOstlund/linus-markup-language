# LML — Linus Markup Language

A native macOS menu bar app for wrapping selected text in XML tags, designed for inline editing with LLMs.

## What it does

1. Select text in any app.
2. Press **⌃⇧L** (Control + Shift + L) — or your custom shortcut.
3. A small panel appears asking for an **action type** (the XML tag name) and an optional **comment**.
4. Press **Return** — the selected text is replaced with:

```xml
<action_type comment="your comment">selected text</action_type>
```

**Example:** Select `"Deploy to staging"`, type `task` / `urgent` → result:

```xml
<task comment="urgent">Deploy to staging</task>
```

## Requirements

- macOS 14 (Sonoma) or later
- Xcode Command Line Tools (`xcode-select --install`)

## Install

### Homebrew

```bash
brew tap LinusOstlund/tap
brew install lml
```

### Build from source

```bash
git clone https://github.com/LinusOstlund/linus-markup-language.git
cd linus-markup-language
make build
./LML
```

## Usage

| Action | How |
|---|---|
| Wrap selected text | **⌃⇧L** or click `⟨/⟩` → Wrap Selected Text |
| Re-use a recent tag | Click `⟨/⟩` → Recent Tags → pick one |
| Clear recent tags | Click `⟨/⟩` → Clear Recent Tags |
| Change hotkey | Click `⟨/⟩` → Settings… → Change… |
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

Open **Settings…** from the menu bar dropdown and click **Change…** to record a new shortcut. The new binding is saved automatically and survives restarts.

## Architecture

LML follows **MVVM + Services** with SwiftUI:

```text
App (LMLApp, AppDelegate)
  └── Views (MenuBarContent, InputPanelView, SettingsView)
        └── ViewModels (MenuBarViewModel, InputPanelViewModel, SettingsViewModel)
              └── Services (HotkeyManager, ClipboardService, TagRepository, WrapFlowService)
                    └── Domain (XMLWrapper, Sanitizer, FuzzyMatcher, Preview, Models)
```

## License

MIT
