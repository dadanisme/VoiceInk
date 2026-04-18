import SwiftUI
import SwiftData

enum SortMode: String {
    case originalAsc = "originalAsc"
    case originalDesc = "originalDesc"
    case replacementAsc = "replacementAsc"
    case replacementDesc = "replacementDesc"
}

enum SortColumn {
    case original
    case replacement
}

struct WordReplacementView: View {
    @Query private var wordReplacements: [WordReplacement]
    @Environment(\.modelContext) private var modelContext
    @State private var showAlert = false
    @State private var editingReplacement: WordReplacement? = nil
    @State private var alertMessage = ""
    @State private var sortMode: SortMode = .originalAsc
    @State private var originalWord = ""
    @State private var replacementWord = ""
    @State private var showInfoPopover = false

    init() {
        if let savedSort = UserDefaults.standard.string(forKey: "wordReplacementSortMode"),
           let mode = SortMode(rawValue: savedSort) {
            _sortMode = State(initialValue: mode)
        }
    }

    private var sortedReplacements: [WordReplacement] {
        switch sortMode {
        case .originalAsc:
            return wordReplacements.sorted { $0.originalText.localizedCaseInsensitiveCompare($1.originalText) == .orderedAscending }
        case .originalDesc:
            return wordReplacements.sorted { $0.originalText.localizedCaseInsensitiveCompare($1.originalText) == .orderedDescending }
        case .replacementAsc:
            return wordReplacements.sorted { $0.replacementText.localizedCaseInsensitiveCompare($1.replacementText) == .orderedAscending }
        case .replacementDesc:
            return wordReplacements.sorted { $0.replacementText.localizedCaseInsensitiveCompare($1.replacementText) == .orderedDescending }
        }
    }
    
    private func toggleSort(for column: SortColumn) {
        switch column {
        case .original:
            sortMode = (sortMode == .originalAsc) ? .originalDesc : .originalAsc
        case .replacement:
            sortMode = (sortMode == .replacementAsc) ? .replacementDesc : .replacementAsc
        }
        UserDefaults.standard.set(sortMode.rawValue, forKey: "wordReplacementSortMode")
    }

    private var shouldShowAddButton: Bool {
        !originalWord.isEmpty || !replacementWord.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.group) {
            GroupBox {
                Label {
                    Text("Define word replacements to automatically replace specific words or phrases")
                        .font(.rowSubtitle)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Button(action: { showInfoPopover.toggle() }) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.tint)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .help("How word replacements work")
                    .popover(isPresented: $showInfoPopover) {
                        WordReplacementInfoPopover()
                    }
                }
            }

            HStack(spacing: Spacing.standard) {
                TextField("Original text (use commas for multiple)", text: $originalWord)
                    .textFieldStyle(.roundedBorder)
                    .font(.rowSubtitle)

                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                    .font(.caption2)
                    .frame(width: 10)

                TextField("Replacement text", text: $replacementWord)
                    .textFieldStyle(.roundedBorder)
                    .font(.rowSubtitle)
                    .onSubmit { addReplacement() }

                if shouldShowAddButton {
                    Button(action: addReplacement) {
                        Image(systemName: "plus.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.tint)
                            .font(.sectionHeader)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .disabled(originalWord.isEmpty || replacementWord.isEmpty)
                    .help("Add word replacement")
                }
            }
            .animation(.easeInOut(duration: 0.2), value: shouldShowAddButton)

            if !wordReplacements.isEmpty {
                VStack(spacing: 0) {
                    HStack(spacing: Spacing.standard) {
                        Button(action: { toggleSort(for: .original) }) {
                            HStack(spacing: Spacing.tight) {
                                Text("Original")
                                    .font(.rowSubtitle)
                                    .foregroundStyle(.secondary)

                                if sortMode == .originalAsc || sortMode == .originalDesc {
                                    Image(systemName: sortMode == .originalAsc ? "chevron.up" : "chevron.down")
                                        .font(.caption)
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .help("Sort by original")

                        Image(systemName: "arrow.right")
                            .foregroundStyle(.secondary)
                            .font(.caption2)
                            .frame(width: 10)

                        Button(action: { toggleSort(for: .replacement) }) {
                            HStack(spacing: Spacing.tight) {
                                Text("Replacement")
                                    .font(.rowSubtitle)
                                    .foregroundStyle(.secondary)

                                if sortMode == .replacementAsc || sortMode == .replacementDesc {
                                    Image(systemName: sortMode == .replacementAsc ? "chevron.up" : "chevron.down")
                                        .font(.caption)
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .help("Sort by replacement")
                    }
                    .padding(.horizontal, Spacing.tight)
                    .padding(.vertical, Spacing.standard)

                    Divider()

                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(sortedReplacements) { replacement in
                                ReplacementRow(
                                    original: replacement.originalText,
                                    replacement: replacement.replacementText,
                                    onDelete: { removeReplacement(replacement) },
                                    onEdit: { editingReplacement = replacement }
                                )

                                if replacement.id != sortedReplacements.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                }
                .padding(.top, Spacing.tight)
            }
        }
        .padding()
        .sheet(item: $editingReplacement) { replacement in
            EditReplacementSheet(replacement: replacement, modelContext: modelContext)
        }
        .alert("Word Replacement", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private func addReplacement() {
        let original = originalWord.trimmingCharacters(in: .whitespacesAndNewlines)
        let replacement = replacementWord.trimmingCharacters(in: .whitespacesAndNewlines)
        if let error = DictionaryService.addWordReplacement(original: original, replacement: replacement, existing: Array(wordReplacements), context: modelContext) {
            alertMessage = error
            showAlert = true
            return
        }
        originalWord = ""
        replacementWord = ""
    }

    private func removeReplacement(_ replacement: WordReplacement) {
        modelContext.delete(replacement)

        do {
            try modelContext.save()
        } catch {
            // Rollback the delete to restore UI consistency
            modelContext.rollback()
            alertMessage = "Failed to remove replacement: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

struct WordReplacementInfoPopover: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.section) {
            Text("How to use Word Replacements")
                .font(.sectionHeader)

            VStack(alignment: .leading, spacing: Spacing.standard) {
                Text("Separate multiple originals with commas:")
                    .font(.rowSubtitle)
                    .foregroundStyle(.secondary)

                Text("Voicing, Voice ink, Voiceing")
                    .font(.callout)
                    .padding(Spacing.standard)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.controlBackground)
                    .cornerRadius(6)
            }

            Divider()

            Text("Examples")
                .font(.rowSubtitle)
                .foregroundStyle(.secondary)

            VStack(spacing: Spacing.comfy) {
                HStack(spacing: Spacing.standard) {
                    VStack(alignment: .leading, spacing: Spacing.tight) {
                        Text("Original:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("my website link")
                            .font(.callout)
                    }

                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: Spacing.tight) {
                        Text("Replacement:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("https://tryvoiceink.com")
                            .font(.callout)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.controlBackground)
                .cornerRadius(6)

                HStack(spacing: Spacing.standard) {
                    VStack(alignment: .leading, spacing: Spacing.tight) {
                        Text("Original:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Voicing, Voice ink")
                            .font(.callout)
                    }

                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: Spacing.tight) {
                        Text("Replacement:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("VoiceInk")
                            .font(.callout)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.controlBackground)
                .cornerRadius(6)
            }
        }
        .padding()
        .frame(width: 380)
    }
}

struct ReplacementRow: View {
    let original: String
    let replacement: String
    let onDelete: () -> Void
    let onEdit: () -> Void
    @State private var isEditHovered = false
    @State private var isDeleteHovered = false

    var body: some View {
        HStack(spacing: Spacing.standard) {
            Text(original)
                .font(.rowSubtitle)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "arrow.right")
                .foregroundStyle(.secondary)
                .font(.caption2)
                .frame(width: 10)

            ZStack(alignment: .trailing) {
                Text(replacement)
                    .font(.rowSubtitle)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, 50)

                HStack(spacing: 6) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(isEditHovered ? Color.accentColor : .secondary)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .help("Edit replacement")
                    .onHover { hover in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isEditHovered = hover
                        }
                    }

                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(isDeleteHovered ? .red : .secondary)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .help("Remove replacement")
                    .onHover { hover in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isDeleteHovered = hover
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, Spacing.standard)
        .padding(.horizontal, Spacing.tight)
    }
}