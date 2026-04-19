import SwiftUI

struct OnboardingModelDownloadView: View {
    @Binding var hasCompletedOnboarding: Bool
    @EnvironmentObject private var whisperModelManager: WhisperModelManager
    @EnvironmentObject private var transcriptionModelManager: TranscriptionModelManager
    @State private var scale: CGFloat = 0.8
    @State private var opacity: CGFloat = 0
    @State private var isDownloading = false
    @State private var isModelSet = false
    @State private var showTutorial = false
    
    private let turboModel = PredefinedModels.models.first { $0.name == "ggml-large-v3-turbo-q5_0" } as! LocalModel
    
    var body: some View {
        ZStack {
            if showTutorial {
                OnboardingTutorialView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                GeometryReader { geometry in
                    // Reusable background
                    OnboardingBackgroundView()
                    
                    VStack(spacing: Spacing.page) {
                        // Model icon and title
                        VStack(spacing: Spacing.page) {
                            // Model icon
                            ZStack {
                                Circle()
                                    .fill(Color.accentColor.opacity(0.1))
                                    .frame(width: 100, height: 100)

                                if isModelSet {
                                    // HIG: decorative — size is layout-critical, not typography
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 50, weight: .regular, design: .default))
                                        .foregroundStyle(Color.accentColor)
                                        .transition(.scale.combined(with: .opacity))
                                } else {
                                    // HIG: decorative — size is layout-critical, not typography
                                    Image(systemName: "brain")
                                        .font(.system(size: 40, weight: .regular, design: .default))
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .scaleEffect(scale)
                            .opacity(opacity)

                            // Title and description
                            VStack(spacing: Spacing.comfy) {
                                Text("Download AI Model")
                                    .font(.titleEmphasis)
                                    .foregroundStyle(.primary)

                                Text("We'll download the optimized model to get you started.")
                                    .font(.rowTitle)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .scaleEffect(scale)
                            .opacity(opacity)
                        }

                        // Model card - Centered and compact
                        VStack(alignment: .leading, spacing: Spacing.section) {
                            // Model name and details
                            VStack(alignment: .center, spacing: Spacing.standard) {
                                Text(turboModel.displayName)
                                    .font(.sectionHeader)
                                    .foregroundStyle(.primary)
                                Text("\(turboModel.size) • \(turboModel.language)")
                                    .font(.rowDetail)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)

                            Divider()

                            // Performance indicators in a more compact layout
                            HStack(spacing: Spacing.group) {
                                performanceIndicator(label: "Speed", value: turboModel.speed)
                                performanceIndicator(label: "Accuracy", value: turboModel.accuracy)
                                ramUsageLabel(gb: turboModel.ramUsage)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)

                            // Download progress
                            if isDownloading {
                                DownloadProgressView(
                                    modelName: turboModel.name,
                                    downloadProgress: whisperModelManager.downloadProgress
                                )
                                .transition(.opacity)
                            }
                        }
                        .padding(Spacing.group)
                        .frame(width: min(geometry.size.width * 0.6, 400))
                        .background(Color.controlBackground.opacity(0.6))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.separatorColor, lineWidth: 1)
                        )
                        .scaleEffect(scale)
                        .opacity(opacity)

                        // Action buttons
                        VStack(spacing: Spacing.section) {
                            Button(action: handleAction) {
                                Text(getButtonTitle())
                                    .frame(minWidth: 200)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .disabled(isDownloading)

                            if !isModelSet {
                                SkipButton(text: "Skip for now") {
                                    withAnimation {
                                        showTutorial = true
                                    }
                                }
                            }
                        }
                        .opacity(opacity)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .frame(width: min(geometry.size.width * 0.8, 600))
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .onAppear {
            animateIn()
            checkModelStatus()
        }
    }
    
    private func animateIn() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            scale = 1
            opacity = 1
        }
    }
    
    private func checkModelStatus() {
        if whisperModelManager.availableModels.contains(where: { $0.name == turboModel.name }) {
            isModelSet = transcriptionModelManager.currentTranscriptionModel?.name == turboModel.name
        }
    }

    private func handleAction() {
        if isModelSet {
            withAnimation {
                showTutorial = true
            }
        } else if whisperModelManager.availableModels.contains(where: { $0.name == turboModel.name }) {
            if let modelToSet = transcriptionModelManager.allAvailableModels.first(where: { $0.name == turboModel.name }) {
                Task {
                    transcriptionModelManager.setDefaultTranscriptionModel(modelToSet)
                    withAnimation {
                        isModelSet = true
                    }
                }
            }
        } else {
            withAnimation {
                isDownloading = true
            }
            Task {
                await whisperModelManager.downloadModel(turboModel)
                if let modelToSet = transcriptionModelManager.allAvailableModels.first(where: { $0.name == turboModel.name }) {
                    transcriptionModelManager.setDefaultTranscriptionModel(modelToSet)
                    withAnimation {
                        isModelSet = true
                        isDownloading = false
                    }
                }
            }
        }
    }

    private func getButtonTitle() -> String {
        if isModelSet {
            return "Continue"
        } else if isDownloading {
            return "Downloading..."
        } else if whisperModelManager.availableModels.contains(where: { $0.name == turboModel.name }) {
            return "Set as Default"
        } else {
            return "Download Model"
        }
    }
    
    private func performanceIndicator(label: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: Spacing.tight) {
            Text(label)
                .font(.rowDetail)
                .foregroundStyle(.secondary)

            HStack(spacing: Spacing.tight) {
                ForEach(0..<5) { index in
                    Circle()
                        .fill(Double(index) / 5.0 <= value ? Color.accentColor : Color.primary.opacity(0.2))
                        .frame(width: 6, height: 6)
                }
            }
        }
    }

    private func ramUsageLabel(gb: Double) -> some View {
        VStack(alignment: .leading, spacing: Spacing.tight) {
            Text("RAM")
                .font(.rowDetail)
                .foregroundStyle(.secondary)

            Text(String(format: "%.1f GB", gb))
                .font(.rowDetail.weight(.bold))
                .foregroundStyle(.primary)
        }
    }
}
