import SwiftUI
import SwiftData

struct DictionarySettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedSection: DictionarySection = .replacements
    @State private var isShowingSettings = false
    let whisperPrompt: WhisperPrompt
    
    enum DictionarySection: String, CaseIterable {
        case replacements = "Word Replacements"
        case spellings = "Vocabulary"
        
        var description: String {
            switch self {
            case .spellings:
                return "Add words to help VoiceInk recognize them properly"
            case .replacements:
                return "Automatically replace specific words/phrases with custom formatted text "
            }
        }
        
        var icon: String {
            switch self {
            case .spellings:
                return "character.book.closed.fill"
            case .replacements:
                return "arrow.2.squarepath"
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                mainContent
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color.controlBackground)
        .slidingPanel(isPresented: $isShowingSettings, width: 400) {
            DictionarySettingsPanel {
                withAnimation(.smooth(duration: 0.3)) {
                    isShowingSettings = false
                }
            }
        }
    }
    
    private var heroSection: some View {
        CompactHeroSection(
            icon: "brain.filled.head.profile",
            title: "Dictionary Settings",
            description: "Enhance VoiceInk's transcription accuracy by teaching it your vocabulary",
            maxDescriptionWidth: 500
        )
    }
    
    private var mainContent: some View {
        VStack(spacing: 40) {
            sectionSelector
            selectedSectionContent
        }
        .padding(.horizontal, Spacing.page)
        .padding(.vertical, 40)
    }

    private var sectionSelector: some View {
        VStack(alignment: .leading, spacing: Spacing.group) {
            HStack {
                Text("Select Section")
                    .font(.titleEmphasis)

                Spacer()

                Button {
                    withAnimation(.smooth(duration: 0.3)) {
                        isShowingSettings.toggle()
                    }
                } label: {
                    Image(systemName: "gear")
                        .font(.sectionHeader)
                        .foregroundStyle(isShowingSettings ? Color.accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .help("Dictionary settings")
            }

            HStack(spacing: Spacing.group) {
                ForEach(DictionarySection.allCases, id: \.self) { section in
                    SectionCard(
                        section: section,
                        isSelected: selectedSection == section,
                        action: { selectedSection = section }
                    )
                }
            }
        }
    }

    private var selectedSectionContent: some View {
        VStack(alignment: .leading, spacing: Spacing.group) {
            switch selectedSection {
            case .spellings:
                SurfaceCard {
                    VocabularyView(whisperPrompt: whisperPrompt)
                }
            case .replacements:
                SurfaceCard {
                    WordReplacementView()
                }
            }
        }
    }
}

struct SectionCard: View {
    let section: DictionarySettingsView.DictionarySection
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SurfaceCard(style: isSelected ? .selected : .plain) {
                VStack(alignment: .leading, spacing: Spacing.comfy) {
                    // HIG: decorative — size is layout-critical, not typography
                    Image(systemName: section.icon)
                        .font(.system(size: 28, weight: .regular, design: .default))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))

                    VStack(alignment: .leading, spacing: Spacing.tight) {
                        Text(section.rawValue)
                            .font(.sectionHeader)

                        Text(section.description)
                            .font(.rowSubtitle)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

