import Foundation
import Combine

/// Drives the input panel's two text fields, fuzzy dropdown, validation,
/// and shake animation. Pure logic — never imports AppKit.
@MainActor
public final class InputPanelViewModel: ObservableObject {

    // MARK: - Published state

    @Published public var actionType: String = ""
    @Published public var comment: String = ""
    @Published public var filteredTags: [FuzzyMatch] = []
    @Published public var showDropdown: Bool = false
    @Published public var shaking: Bool = false

    /// Set by the presenter; the view reads this to show a preview label.
    @Published public var selectedTextPreview: String = ""

    // MARK: - Private

    private let recentTags: [String]
    private let completion: (String, String) -> Void
    private let cancellation: () -> Void
    private var cancellables = Set<AnyCancellable>()

    public init(
        selectedText: String,
        prefilledTag: String?,
        recentTags: [String],
        onOK: @escaping (String, String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.recentTags = recentTags
        self.completion = onOK
        self.cancellation = onCancel
        self.selectedTextPreview = Preview.format(selectedText)

        if let tag = prefilledTag {
            self.actionType = tag
        }

        // Re-run fuzzy filter whenever the action type field changes.
        $actionType
            .removeDuplicates()
            .sink { [weak self] query in self?.updateDropdown(query: query) }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    public func confirm() {
        let sanitized = Sanitizer.sanitizeActionType(actionType)
        guard !sanitized.isEmpty else {
            shake()
            return
        }
        completion(sanitized, comment)
    }

    public func cancel() {
        cancellation()
    }

    // MARK: - Fuzzy dropdown

    private func updateDropdown(query: String) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            filteredTags = []
            showDropdown = false
            return
        }
        let ranked = FuzzyMatcher.rankWithMatches(query: query, candidates: recentTags)
        filteredTags = ranked
        showDropdown = !ranked.isEmpty
    }

    public func selectTag(_ match: FuzzyMatch) {
        actionType = match.tag
        showDropdown = false
    }

    // MARK: - Shake

    private func shake() {
        shaking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.shaking = false
        }
    }
}
