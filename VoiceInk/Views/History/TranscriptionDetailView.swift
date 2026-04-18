import SwiftUI

struct TranscriptionDetailView: View {
    let transcription: Transcription
    var onInfoTap: (() -> Void)?

    private var hasAudioFile: Bool {
        if let urlString = transcription.audioFileURL,
           let url = URL(string: urlString),
           FileManager.default.fileExists(atPath: url.path) {
            return true
        }
        return false
    }

    var body: some View {
        VStack(spacing: Spacing.comfy) {
            ScrollView {
                VStack(spacing: Spacing.section) {
                    MessageBubble(
                        label: "Original",
                        text: transcription.text,
                        isEnhanced: false
                    )

                    if let enhancedText = transcription.enhancedText {
                        MessageBubble(
                            label: "Enhanced",
                            text: enhancedText,
                            isEnhanced: true
                        )
                    }
                }
                .padding(Spacing.section)
            }

            if hasAudioFile, let urlString = transcription.audioFileURL,
               let url = URL(string: urlString) {
                VStack(spacing: 0) {
                    Divider()

                    AudioPlayerView(url: url, transcription: transcription, onInfoTap: onInfoTap)
                        .padding(.horizontal, Spacing.standard)
                        .padding(.vertical, Spacing.tight)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.controlBackground.opacity(0.5))
                        )
                        .padding(.horizontal, Spacing.comfy)
                        .padding(.top, Spacing.tight)
                }
            }
        }
        .padding(.vertical, Spacing.comfy)
        .background(Color.controlBackground)
    }
}

private struct MessageBubble: View {
    let label: String
    let text: String
    let isEnhanced: Bool

    var body: some View {
        HStack(alignment: .bottom) {
            if isEnhanced { Spacer(minLength: 60) }

            VStack(alignment: isEnhanced ? .leading : .trailing, spacing: Spacing.tight) {
                Text(label)
                    .font(.rowDetail)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, Spacing.comfy)

                ScrollView {
                    Text(text)
                        .font(.rowTitle)
                        .lineSpacing(2)
                        .textSelection(.enabled)
                        .padding(.horizontal, Spacing.comfy)
                        .padding(.vertical, Spacing.standard)
                }
                .frame(maxHeight: 350)
                .background {
                    if isEnhanced {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.accentColor.opacity(0.2))
                    } else {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.thinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(Color.separatorColor.opacity(0.6), lineWidth: 0.5)
                            )
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    CopyIconButton(textToCopy: text)
                        .padding(Spacing.standard)
                }
            }

            if !isEnhanced { Spacer(minLength: 60) }
        }
    }


}
