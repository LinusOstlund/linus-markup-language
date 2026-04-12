import AppKit
import LMLCore

/// Minimal `NSApplicationDelegate` bridged into SwiftUI via
/// `@NSApplicationDelegateAdaptor`. Owns the service graph, wires
/// the hotkey, and presents the input panel.
///
/// Everything that touches Carbon or CGEvent lives in a service;
/// this class is just the wiring harness.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Services

    let tagRepo = TagRepository()
    let prefsRepo = PreferencesRepository()
    let clipboard = ClipboardService()
    let hotkeyManager = HotkeyManager()
    lazy var wrapFlow = WrapFlowService(clipboard: clipboard, tags: tagRepo)
    let panelPresenter = InputPanelPresenter()

    // MARK: - ViewModels (owned here so they survive view rebuilds)

    lazy var menuBarVM = MenuBarViewModel(tags: tagRepo, prefs: prefsRepo)
    lazy var settingsVM = SettingsViewModel(prefs: prefsRepo, hotkeyManager: hotkeyManager)

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        AccessibilityGuard.ensureAccess()

        // Register hotkey (persisted or default)
        let binding = prefsRepo.loadHotkey()
        hotkeyManager.register(binding)
        hotkeyManager.onTrigger = { [weak self] in
            self?.triggerWrap(prefilledTag: nil)
        }

        // Wire WrapFlowService callbacks
        wrapFlow.presentPanel = { [weak self] selectedText, prefilledTag in
            guard let self else { return nil }
            return await self.panelPresenter.present(
                selectedText: selectedText,
                prefilledTag: prefilledTag,
                recentTags: self.tagRepo.loadRecent().map(\.name)
            )
        }
        wrapFlow.showNotification = { message in
            NotificationToast.show(message)
        }

        // Wire menu bar VM
        menuBarVM.onWrap = { [weak self] prefilledTag in
            self?.triggerWrap(prefilledTag: prefilledTag)
        }
    }

    // MARK: - Wrap trigger

    private func triggerWrap(prefilledTag: String?) {
        wrapFlow.run(prefilledTag: prefilledTag)

        // Refresh the menu after the flow completes (debounced — the flow
        // is async and we just fire-and-forget the refresh).
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.menuBarVM.refresh()
        }
    }
}
