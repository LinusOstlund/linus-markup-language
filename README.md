<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/logo-light.svg">
    <img src="docs/logo.svg" width="80" alt="LML — a proofreader's caret">
  </picture>
</p>

<h1 align="center">LML</h1>

<p align="center"><em>Proofreader's marks for the age of LLMs.</em></p>

<br>

Select text. Tag it. Hand it off.

LML is a tiny macOS menu bar app that wraps selected text in XML tags — inline, in any editor. Like a proofreader marking up a manuscript, but the reader is a >200 IQ language model that has read the complete internet + all pirated books in existence _at least_ twice.

---

# Why do I need this?

You use AI. You use a text editor. But the two don't talk to each other; you copy text out, explain what you want in a chat window, then paste the result back in, the LLM misunderstands you, _ad infinitum_.

LML closes that gap. Select text, annotate it with a tag and a comment, and hand it back. Structured, inline, in XML that agentic AI already knows how to read. Tags can be nested, are self-explanatory and can be adressed in parallell by Claude Code.

### Example: find a reference

**Before:**

> * To write is human; to edit is divine
> * The essence of writing is rewriting.

**⌃⇧L** → action: `Find Source` · comment: *"Who said this now again? Find reference and add markdown urls."*
**After:**

```xml
<find_source comment="find citations from Clean Code and TDD by Example">
> * To write is human; to edit is divine
> * The essence of writing is rewriting.
</find_source>
```

And violá:

> * [To write is human; to edit is divine](https://www.goodreads.com/quotes/299449-to-write-is-human-to-edit-is-divine) — Stephen King, *On Writing*
> * [The essence of writing is rewriting.](https://quoteinvestigator.com/2023/08/22/writing-rewriting/) — William Zinsser, *On Writing Well*

---

## More examples

### Editing Plans

Depending on your Agentic system (Claude Code et al), each LML-tag will fire a subagent, giving you parallell edits.
Here's an example from an early plan file:

```bash
## 4. Create PAT for the CI workflow

The `update-tap` job in `.github/workflows/release.yml` needs to push to the
`homebrew-tap` repo. `GITHUB_TOKEN` is scoped to the current repo only, so we need a cross-repo token.
```

Who wants a cross repo-toke? Add a tag _Remove redundancy_ with a comment:

```xml
<remove_redundancy comment="Yeah, we're not doing this. Suggest a simpler approach.">cross-repo token.</remove_redundancy>
```

### Improving prose

You're drafting a blog post:

> I'm also notoriously bad at one-shotting good english on my first drafts. It is boring to be talking two languages at the same time when the world is talking english not swedish.
 
You want to improve grammar and find synonyms:

```xml
<improve_grammar comment="very 'svengelska', tighten the language">I'm also notoriously bad at one-shotting good english on my first drafts. It is boring to be <synonom comment="is 'talking' correct in this context?">talking</synonom> two languages at the same time when the world is talking english not swedish.</improve_grammar>
```

You can nest tags, too.

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

Requires macOS 14 (Sonoma) or later and Xcode Command Line Tools.

## Usage

**⌃⇧L** opens the tag panel. Type an action, add a comment, press Return. Done.

- **Tab** moves between fields
- **Escape** cancels
- **Return** confirms
- Recent tags are saved and reused from the menu bar dropdown
- Fuzzy search finds tags as you type

Change the hotkey in **Settings** from the `⟨/⟩` menu bar dropdown.

## Permissions

LML needs **Accessibility** access to read and replace selected text via simulated ⌘C / ⌘V. Grant it at System Settings → Privacy & Security → Accessibility, then relaunch.

<details>
<summary><strong>Architecture</strong></summary>

<br>

MVVM + Services, SwiftUI:

```text
App (LMLApp, AppDelegate)
  └── Views (MenuBarContent, InputPanelView, SettingsView)
        └── ViewModels (MenuBarViewModel, InputPanelViewModel, SettingsViewModel)
              └── Services (HotkeyManager, ClipboardService, TagRepository, WrapFlowService)
                    └── Domain (XMLWrapper, Sanitizer, FuzzyMatcher, Preview, Models)
```

</details>

## License

[MIT](LICENSE)