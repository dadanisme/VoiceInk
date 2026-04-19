import SwiftUI

struct VoiceInkButton: View {
    let title: String
    let action: () -> Void
    var isDisabled: Bool = false

    var body: some View {
        Button(title, action: action)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .disabled(isDisabled)
    }
}

struct PowerModeEmptyStateView: View {
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: Spacing.section) {
            // HIG: decorative — size is layout-critical, not typography
            Image(systemName: "bolt.circle.fill")
                .font(.system(size: 48, weight: .regular, design: .default))
                .foregroundStyle(.secondary)

            Text("No Power Modes")
                .font(.titleEmphasis)

            Text("Add customized power modes for different contexts")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VoiceInkButton(
                title: "Add New Power Mode",
                action: action
            )
            .frame(maxWidth: 250)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PowerModeConfigurationsGrid: View {
    @ObservedObject var powerModeManager: PowerModeManager
    let onEditConfig: (PowerModeConfig) -> Void
    @EnvironmentObject var enhancementService: AIEnhancementService
    
    var body: some View {
        LazyVStack(spacing: Spacing.comfy) {
            ForEach($powerModeManager.configurations) { $config in
                ConfigurationRow(
                    config: $config,
                    isEditing: false,
                    powerModeManager: powerModeManager,
                    onEditConfig: onEditConfig
                )
            }
        }
    }
}

/// Small, consistent icon-only add button used across Power Mode configuration rows.
struct AddIconButton: View {
    let helpText: String
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus.circle.fill")
                .font(.titleEmphasis)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(helpText)
        .accessibilityLabel(helpText)
        .disabled(isDisabled)
    }
}

struct ConfigurationRow: View {
    @Binding var config: PowerModeConfig
    let isEditing: Bool
    let powerModeManager: PowerModeManager
    let onEditConfig: (PowerModeConfig) -> Void
    @EnvironmentObject var enhancementService: AIEnhancementService
    @EnvironmentObject var transcriptionModelManager: TranscriptionModelManager
    @State private var isHovering = false
    
    private let maxAppIconsToShow = 5
    
    private var selectedPrompt: CustomPrompt? {
        guard let promptId = config.selectedPrompt,
              let uuid = UUID(uuidString: promptId) else { return nil }
        return enhancementService.allPrompts.first { $0.id == uuid }
    }
    
    private var selectedModel: String? {
        if let modelName = config.selectedTranscriptionModelName,
           let model = transcriptionModelManager.allAvailableModels.first(where: { $0.name == modelName }) {
            return model.displayName
        }
        return "Default"
    }
    
    private var selectedLanguage: String? {
        if let langCode = config.selectedLanguage {
            if langCode == "auto" { return "Auto" }
            if langCode == "en" { return "English" }
            
            if let modelName = config.selectedTranscriptionModelName,
               let model = transcriptionModelManager.allAvailableModels.first(where: { $0.name == modelName }),
               let langName = model.supportedLanguages[langCode] {
                return langName
            }
            return langCode.uppercased()
        }
        return "Default"
    }
    
    private var appCount: Int { return config.appConfigs?.count ?? 0 }
    private var websiteCount: Int { return config.urlConfigs?.count ?? 0 }
    
    private var websiteText: String {
        if websiteCount == 0 { return "" }
        return websiteCount == 1 ? "1 Website" : "\(websiteCount) Websites"
    }
    
    private var appText: String {
        if appCount == 0 { return "" }
        return appCount == 1 ? "1 App" : "\(appCount) Apps"
    }
    
    private var extraAppsCount: Int {
        return max(0, appCount - maxAppIconsToShow)
    }
    
    private var visibleAppConfigs: [AppConfig] {
        return Array(config.appConfigs?.prefix(maxAppIconsToShow) ?? [])
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Spacing.comfy) {
                ZStack {
                    Circle()
                        .fill(Color.controlBackground)
                        .frame(width: 40, height: 40)

                    Text(config.emoji)
                        .font(.titleEmphasis)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: Spacing.standard) {
                        Text(config.name)
                            .font(.rowTitle.weight(.semibold))

                        if config.isDefault {
                            Text("Default")
                                .font(.rowDetail)
                                .padding(.horizontal, Spacing.standard)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.accentColor))
                                .foregroundStyle(.primary)
                        }
                    }

                    HStack(spacing: Spacing.comfy) {
                        if appCount > 0 {
                            HStack(spacing: Spacing.tight) {
                                Image(systemName: "app.fill")
                                    .font(.caption2)
                                Text(appText)
                                    .font(.caption2)
                            }
                        }

                        if websiteCount > 0 {
                            HStack(spacing: Spacing.tight) {
                                Image(systemName: "globe")
                                    .font(.caption2)
                                Text(websiteText)
                                    .font(.caption2)
                            }
                        }
                    }
                    .padding(.top, 2)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle("", isOn: $config.isEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    .labelsHidden()
                    .onChange(of: config.isEnabled) { _, _ in
                        powerModeManager.updateConfiguration(config)
                    }
            }
            .padding(.vertical, Spacing.comfy)
            .padding(.horizontal, Spacing.section)

            if selectedModel != nil || selectedLanguage != nil || config.isAIEnhancementEnabled || config.autoSendKey.isEnabled {
                Divider()

                HStack(spacing: Spacing.standard) {
                    if let model = selectedModel, model != "Default" {
                        HStack(spacing: Spacing.tight) {
                            Image(systemName: "waveform")
                                .font(.caption2)
                            Text(model)
                                .font(.caption)
                        }
                        .padding(.horizontal, Spacing.standard)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.controlBackground))
                        .overlay(
                            Capsule()
                                .stroke(Color.separatorColor, lineWidth: 0.5)
                        )
                    }

                    if let language = selectedLanguage, language != "Default" {
                        HStack(spacing: Spacing.tight) {
                            Image(systemName: "globe")
                                .font(.caption2)
                            Text(language)
                                .font(.caption)
                        }
                        .padding(.horizontal, Spacing.standard)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.controlBackground))
                        .overlay(
                            Capsule()
                                .stroke(Color.separatorColor, lineWidth: 0.5)
                        )
                    }

                    if config.isAIEnhancementEnabled, let modelName = config.selectedAIModel, !modelName.isEmpty {
                        HStack(spacing: Spacing.tight) {
                            Image(systemName: "cpu")
                                .font(.caption2)
                            Text(modelName.count > 20 ? String(modelName.prefix(18)) + "..." : modelName)
                                .font(.caption)
                        }
                        .padding(.horizontal, Spacing.standard)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.controlBackground))
                        .overlay(
                            Capsule()
                                .stroke(Color.separatorColor, lineWidth: 0.5)
                        )
                    }

                    if config.autoSendKey.isEnabled {
                        HStack(spacing: Spacing.tight) {
                            Image(systemName: "keyboard")
                                .font(.caption2)
                            Text(config.autoSendKey.displayName)
                                .font(.caption)
                        }
                        .padding(.horizontal, Spacing.standard)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.controlBackground))
                        .overlay(
                            Capsule()
                                .stroke(Color.separatorColor, lineWidth: 0.5)
                        )
                    }
                    if config.isAIEnhancementEnabled {
                        if config.useScreenCapture {
                            HStack(spacing: Spacing.tight) {
                                Image(systemName: "camera.viewfinder")
                                    .font(.caption2)
                                Text("Context Awareness")
                                    .font(.caption)
                            }
                            .padding(.horizontal, Spacing.standard)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.controlBackground))
                            .overlay(
                                Capsule()
                                    .stroke(Color.separatorColor, lineWidth: 0.5)
                            )
                        }

                        HStack(spacing: Spacing.tight) {
                            Image(systemName: "sparkles")
                                .font(.caption2)
                            Text(selectedPrompt?.title ?? "AI")
                                .font(.caption)
                        }
                        .padding(.horizontal, Spacing.standard)
                        .padding(.vertical, 2)
                        .background(Capsule()
                            .fill(Color.accentColor.opacity(0.1)))
                        .foregroundStyle(Color.accentColor)
                    }

                    Spacer()
                }

                .padding(.vertical, Spacing.standard)
                .padding(.horizontal, Spacing.section)
                .background(Color.controlBackground.opacity(0.5))
            }
    }
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .background(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(isEditing ? Color.accentColor.opacity(0.15) : Color.controlBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.separatorColor.opacity(0.6), lineWidth: 0.5)
            )
    )
    .opacity(config.isEnabled ? 1.0 : 0.5)

    .onHover { hovering in
        withAnimation(.easeInOut(duration: 0.15)) {
            isHovering = hovering
        }
    }
    .onTapGesture(count: 2) {
        onEditConfig(config)
    }
    .contextMenu {
        Button(action: {
            onEditConfig(config)
        }) {
            Label("Edit", systemImage: "pencil")
        }
        Button(role: .destructive, action: {
            let alert = NSAlert()
            alert.messageText = "Delete Power Mode?"
            alert.informativeText = "Are you sure you want to delete the '\(config.name)' power mode? This action cannot be undone."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Delete")
            alert.addButton(withTitle: "Cancel")
            alert.buttons[0].hasDestructiveAction = true
            
            if alert.runModal() == .alertFirstButtonReturn {
                powerModeManager.removeConfiguration(with: config.id)
            }
        }) {
            Label("Delete", systemImage: "trash")
        }
    }
    }
    
    private var isSelected: Bool {
        return isEditing
    }
}

struct PowerModeAppIcon: View {
    let bundleId: String
    
    var body: some View {
        if let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: appUrl.path))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
        } else {
            Image(systemName: "app.fill")
                .font(.rowSubtitle)
                .foregroundStyle(.secondary)
                .frame(width: 20, height: 20)
        }
    }
}

struct AppGridItem: View {
    let app: (url: URL, name: String, bundleId: String, icon: NSImage)
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.standard) {
                Image(nsImage: app.icon)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .cornerRadius(8)
                    .shadow(color: Color(NSColor.shadowColor).opacity(0.1), radius: 2, x: 0, y: 1)
                Text(app.name)
                    .font(.caption2)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 28)
            }
            .frame(width: 80, height: 80)
            .padding(Spacing.standard)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
