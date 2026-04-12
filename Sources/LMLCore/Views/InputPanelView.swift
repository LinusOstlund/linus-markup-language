import SwiftUI

/// Pure SwiftUI replacement for the old frame-based `InputPanelController`.
/// Hosted inside an `NSPanel` by `InputPanelPresenter` to get floating-panel
/// behaviour (key window without activating Dock icon).
public struct InputPanelView: View {

    @ObservedObject public var viewModel: InputPanelViewModel
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case actionType, comment
    }

    public init(viewModel: InputPanelViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Preview of selected text
            Text(viewModel.selectedTextPreview)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)

            // Action type
            VStack(alignment: .leading, spacing: 4) {
                Text("Action type")
                    .font(.system(size: 12, weight: .medium))

                TextField("e.g. find source, improve humour, make concise",
                          text: $viewModel.actionType)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .actionType)
                    .onSubmit { viewModel.confirm() }

                // Fuzzy dropdown
                if viewModel.showDropdown {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(viewModel.filteredTags) { match in
                                Button {
                                    viewModel.selectTag(match)
                                    focusedField = .comment
                                } label: {
                                    Text(highlightedTag(match))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 6)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxHeight: 132) // ~6 rows
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                }
            }

            // Comment
            VStack(alignment: .leading, spacing: 4) {
                Text("Comment")
                    .font(.system(size: 12, weight: .medium))

                TextField("Free text instruction (optional)",
                          text: $viewModel.comment)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .comment)
                    .onSubmit { viewModel.confirm() }
            }

            // Buttons
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    viewModel.cancel()
                }
                .keyboardShortcut(.cancelAction)

                Button("OK") {
                    viewModel.confirm()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
        .frame(width: 380)
        .offset(x: viewModel.shaking ? 6 : 0)
        .animation(
            viewModel.shaking
                ? .default.repeatCount(5, autoreverses: true).speed(6)
                : .default,
            value: viewModel.shaking
        )
        .onAppear { focusedField = .actionType }
    }

    /// Builds an `AttributedString` where matched characters are bold + accent
    /// color and unmatched characters are secondary gray.
    private func highlightedTag(_ match: FuzzyMatch) -> AttributedString {
        var result = AttributedString(match.tag)
        result.foregroundColor = .secondary
        result.font = .system(size: 13)

        for (offset, _) in match.tag.enumerated() {
            if match.matchedIndices.contains(offset) {
                let start = result.index(result.startIndex, offsetByCharacters: offset)
                let end = result.index(start, offsetByCharacters: 1)
                result[start..<end].foregroundColor = .accentColor
                result[start..<end].font = .system(size: 13, weight: .semibold)
            }
        }

        return result
    }
}
