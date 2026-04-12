import SwiftUI

/// The dropdown that appears when the user clicks the ⟨/⟩ menu bar icon.
public struct MenuBarContent: View {

    @ObservedObject public var viewModel: MenuBarViewModel

    public init(viewModel: MenuBarViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Button("Wrap Selected Text  \(viewModel.hotkeyLabel)") {
            viewModel.wrapSelectedText()
        }
        .keyboardShortcut(.init(.init("l")), modifiers: [.control, .shift])

        Divider()

        if viewModel.recentTags.isEmpty {
            Text("No recent tags")
                .foregroundStyle(.secondary)
        } else {
            Menu("Recent Tags") {
                ForEach(viewModel.recentTags) { tag in
                    Button(tag.name) {
                        viewModel.wrapSelectedText(prefilledTag: tag.name)
                    }
                }
            }

            Button("Clear Recent Tags") {
                viewModel.clearRecentTags()
            }
        }

        Divider()

        SettingsLink {
            Text("Settings…")
        }

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
