import SwiftUI
import KeyboardShortcuts

struct DictionarySettingsPanel: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: Spacing.comfy) {
                Text("Dictionary Settings")
                    .font(.sectionHeader)
                    .foregroundStyle(.primary)

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.rowTitle)
                        .foregroundStyle(.secondary)
                        .padding(6)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .help("Close")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, Spacing.section)
            .background(Color.windowBackground)
            .overlay(
                Divider().opacity(0.5), alignment: .bottom
            )

            // Content
            Form {
                Section {
                    LabeledContent("Quick Add to Dictionary") {
                        KeyboardShortcuts.Recorder(for: .quickAddToDictionary)
                            .controlSize(.small)
                    }
                } header: {
                    Text("Shortcuts")
                }

            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
        }
    }
}
