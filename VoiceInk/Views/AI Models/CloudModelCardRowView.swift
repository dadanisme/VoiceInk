import SwiftUI
import AppKit
import LLMkit

// MARK: - Cloud Model Card View
struct CloudModelCardView: View {
    let model: CloudModel
    let isCurrent: Bool
    var setDefaultAction: () -> Void

    @EnvironmentObject private var transcriptionModelManager: TranscriptionModelManager
    @State private var isExpanded = false
    @State private var apiKey = ""
    @State private var isVerifying = false
    @State private var verificationStatus: VerificationStatus = .none
    @State private var verificationError: String? = nil

    enum VerificationStatus {
        case none, verifying, success, failure
    }

    private var isConfigured: Bool {
        return APIKeyManager.shared.hasAPIKey(forProvider: providerKey)
    }

    private var providerKey: String {
        switch model.provider {
        case .groq:
            return "Groq"
        case .elevenLabs:
            return "ElevenLabs"
        case .deepgram:
            return "Deepgram"
        case .mistral:
            return "Mistral"
        case .gemini:
            return "Gemini"
        case .soniox:
            return "Soniox"
        case .speechmatics:
            return "Speechmatics"
        default:
            return model.provider.rawValue
        }
    }

    var body: some View {
        SurfaceCard(style: isCurrent ? .selected : .plain) {
            VStack(alignment: .leading, spacing: 0) {
                // Main card content
                HStack(alignment: .top, spacing: Spacing.section) {
                    VStack(alignment: .leading, spacing: Spacing.standard) {
                        headerSection
                        metadataSection
                        descriptionSection
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    actionSection
                }

                // Expandable configuration section
                if isExpanded {
                    Divider()
                        .padding(.vertical, Spacing.comfy)

                    configurationSection
                }
            }
        }
        .onAppear {
            loadSavedAPIKey()
        }
    }

    private var headerSection: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(model.displayName)
                .font(.rowTitle)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            statusBadge

            Spacer()
        }
    }

    private var statusBadge: some View {
        Group {
            if isCurrent {
                Text("Default")
                    .font(.rowDetail)
                    .fontWeight(.medium)
                    .padding(.horizontal, Spacing.standard)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.accentColor))
                    .foregroundStyle(.primary)
            } else if isConfigured {
                Text("Configured")
                    .font(.rowDetail)
                    .fontWeight(.medium)
                    .padding(.horizontal, Spacing.standard)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color(.systemGreen).opacity(0.2)))
                    .foregroundStyle(Color(.systemGreen))
            } else {
                Text("Setup Required")
                    .font(.rowDetail)
                    .fontWeight(.medium)
                    .padding(.horizontal, Spacing.standard)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color(.systemOrange).opacity(0.2)))
                    .foregroundStyle(Color(.systemOrange))
            }
        }
    }

    private var metadataSection: some View {
        HStack(spacing: Spacing.comfy) {
            // Provider
            Label(model.provider.rawValue, systemImage: "cloud")
                .font(.rowDetail)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            // Language
            Label(model.language, systemImage: "globe")
                .font(.rowDetail)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            // Speed
            HStack(spacing: 3) {
                Text("Speed")
                    .font(.rowDetail)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                progressDotsWithNumber(value: model.speed * 10)
            }
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)

            // Accuracy
            HStack(spacing: 3) {
                Text("Accuracy")
                    .font(.rowDetail)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                progressDotsWithNumber(value: model.accuracy * 10)
            }
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
        }
        .lineLimit(1)
    }

    private var descriptionSection: some View {
        Text(model.description)
            .font(.rowDetail)
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, Spacing.tight)
    }

    private var actionSection: some View {
        HStack(spacing: Spacing.standard) {
            if isCurrent {
                Text("Default Model")
                    .font(.rowSubtitle)
                    .foregroundStyle(.secondary)
            } else if isConfigured {
                Button(action: setDefaultAction) {
                    Text("Set as Default")
                        .font(.rowSubtitle)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else {
                Button(action: {
                    withAnimation(.interpolatingSpring(stiffness: 170, damping: 20)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack(spacing: Spacing.tight) {
                        Text("Configure")
                        Image(systemName: "gear")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            if isConfigured {
                Menu {
                    Button {
                        clearAPIKey()
                    } label: {
                        Label("Remove API Key", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.rowTitle)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .frame(width: 20, height: 20)
                .help("More actions")
            }
        }
    }

    private var configurationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.comfy) {
            Text("API Key Configuration")
                .font(.rowTitle)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            HStack(spacing: Spacing.standard) {
                SecureField("Enter your \(model.provider.rawValue) API key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isVerifying)

                Button(action: verifyAPIKey) {
                    HStack(spacing: Spacing.tight) {
                        if isVerifying {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 12, height: 12)
                        } else {
                            Image(systemName: verificationStatus == .success ? "checkmark" : "checkmark.shield")
                        }
                        Text(isVerifying ? "Verifying..." : "Verify")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(apiKey.isEmpty || isVerifying)
            }

            if verificationStatus == .failure {
                if let error = verificationError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color(.systemRed))
                } else {
                    Text("Verification failed")
                        .font(.caption)
                        .foregroundStyle(Color(.systemRed))
                }
            } else if verificationStatus == .success {
                Text("API key verified successfully!")
                    .font(.caption)
                    .foregroundStyle(Color(.systemGreen))
            }
        }
    }

    private func loadSavedAPIKey() {
        if let savedKey = APIKeyManager.shared.getAPIKey(forProvider: providerKey) {
            apiKey = savedKey
            verificationStatus = .success
        }
    }

    private func verifyAPIKey() {
        guard !apiKey.isEmpty else { return }

        isVerifying = true
        verificationStatus = .verifying
        let key = apiKey

        Task {
            let result: (isValid: Bool, errorMessage: String?)
            switch model.provider {
            case .groq:
                result = await OpenAILLMClient.verifyAPIKey(
                    baseURL: URL(string: "https://api.groq.com/openai/v1/chat/completions")!,
                    apiKey: key,
                    model: model.name
                )
            case .elevenLabs:
                result = await ElevenLabsClient.verifyAPIKey(key)
            case .deepgram:
                result = await DeepgramClient.verifyAPIKey(key)
            case .mistral:
                result = await MistralTranscriptionClient.verifyAPIKey(key)
            case .gemini:
                result = await GeminiTranscriptionClient.verifyAPIKey(key)
            case .soniox:
                result = await SonioxClient.verifyAPIKey(key)
            case .speechmatics:
                result = await SpeechmaticsClient.verifyAPIKey(key)
            default:
                await MainActor.run {
                    isVerifying = false
                    verificationStatus = .failure
                    verificationError = "Unsupported provider"
                }
                return
            }

            await MainActor.run {
                isVerifying = false
                if result.isValid {
                    verificationStatus = .success
                    verificationError = nil
                    APIKeyManager.shared.saveAPIKey(key, forProvider: providerKey)
                    transcriptionModelManager.refreshAllAvailableModels()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded = false
                    }
                } else {
                    verificationStatus = .failure
                    verificationError = result.errorMessage
                }
            }
        }
    }

    private func clearAPIKey() {
        APIKeyManager.shared.deleteAPIKey(forProvider: providerKey)
        apiKey = ""
        verificationStatus = .none
        verificationError = nil

        if isCurrent {
            transcriptionModelManager.clearCurrentTranscriptionModel()
        }

        transcriptionModelManager.refreshAllAvailableModels()

        withAnimation(.easeInOut(duration: 0.3)) {
            isExpanded = false
        }
    }
}
