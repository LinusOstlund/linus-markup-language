import Foundation

/// Backs the MenuBarExtra content view: recent tags list, wrap trigger,
/// and clear action. Pure observable state — views bind, nothing more.
@MainActor
public final class MenuBarViewModel: ObservableObject {

    @Published public private(set) var recentTags: [Tag] = []
    @Published public private(set) var hotkeyLabel: String = ""

    private let tags: TagRepositoryProtocol
    private let prefs: PreferencesRepositoryProtocol

    /// Called when the user picks "Wrap Selected Text" from the menu.
    public var onWrap: ((_ prefilledTag: String?) -> Void)?

    public init(tags: TagRepositoryProtocol, prefs: PreferencesRepositoryProtocol) {
        self.tags = tags
        self.prefs = prefs
        refresh()
    }

    public func refresh() {
        recentTags = tags.loadRecent()
        hotkeyLabel = prefs.loadHotkey().displayString
    }

    public func wrapSelectedText(prefilledTag: String? = nil) {
        onWrap?(prefilledTag)
    }

    public func clearRecentTags() {
        tags.clear()
        refresh()
    }
}
