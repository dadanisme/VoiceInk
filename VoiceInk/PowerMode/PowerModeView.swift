import SwiftUI
import SwiftData

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .center,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

enum ConfigurationMode: Hashable {
    case add
    case edit(PowerModeConfig)
    
    var isAdding: Bool {
        if case .add = self { return true }
        return false
    }
    
    var title: String {
        switch self {
        case .add: return "Add Power Mode"
        case .edit: return "Edit Power Mode"
        }
    }
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .add:
            hasher.combine(0)
        case .edit(let config):
            hasher.combine(1)
            hasher.combine(config.id)
        }
    }
    
    static func == (lhs: ConfigurationMode, rhs: ConfigurationMode) -> Bool {
        switch (lhs, rhs) {
        case (.add, .add):
            return true
        case (.edit(let lhsConfig), .edit(let rhsConfig)):
            return lhsConfig.id == rhsConfig.id
        default:
            return false
        }
    }
}

enum ConfigurationType {
    case application
    case website
}

let commonEmojis = ["🏢", "🏠", "💼", "🎮", "📱", "📺", "🎵", "📚", "✏️", "🎨", "🧠", "⚙️", "💻", "🌐", "📝", "📊", "🔍", "💬", "📈", "🔧"]

struct PowerModeView: View {
    @StateObject private var powerModeManager = PowerModeManager.shared
    @EnvironmentObject private var enhancementService: AIEnhancementService
    @EnvironmentObject private var aiService: AIService
    @State private var configurationMode: ConfigurationMode?
    @State private var isPanelOpen = false
    @State private var panelID = UUID()
    @State private var isReorderPanelOpen = false
    
    var body: some View {
            VStack(spacing: 0) {
                // Header Section
                VStack(spacing: Spacing.comfy) {
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.tight) {
                            HStack(spacing: Spacing.standard) {
                                Text("Power Modes")
                                    .font(.largeTitle)
                                    .foregroundStyle(.primary)

                                InfoTip(
                                    "Automatically apply custom configurations based on the app/website you are using.",
                                    learnMoreURL: "https://tryvoiceink.com/docs/power-mode"
                                )
                            }

                            Text("Automate your workflows with context-aware configurations.")
                                .font(.rowTitle)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        HStack(spacing: Spacing.standard) {
                            Button {
                                openPanel(mode: .add)
                            } label: {
                                Label("Add Power Mode", systemImage: "plus")
                            }
                            .buttonStyle(.borderedProminent)

                            Button {
                                openReorderPanel()
                            } label: {
                                Label("Reorder", systemImage: "arrow.up.arrow.down")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding(.horizontal, Spacing.group)
                .padding(.top, Spacing.group)
                .padding(.bottom, Spacing.section)
                .frame(maxWidth: .infinity)
                .background(Color.windowBackground)
                
                // Content Section
                Group {
                        GeometryReader { geometry in
                            ScrollView {
                                VStack(spacing: 0) {
                                    if powerModeManager.configurations.isEmpty {
                                        VStack(spacing: Spacing.group) {
                                            Spacer()
                                                .frame(height: geometry.size.height * 0.2)

                                            VStack(spacing: Spacing.section) {
                                                Image(systemName: "square.grid.2x2.fill")
                                                    .font(.system(size: 48, weight: .regular))
                                                    .foregroundStyle(.tertiary)

                                                VStack(spacing: Spacing.standard) {
                                                    Text("No Power Modes Yet")
                                                        .font(.titleEmphasis)
                                                        .foregroundStyle(.primary)

                                                    Text("Create first power mode to automate your VoiceInk workflow based on apps/website you are using")
                                                        .font(.rowTitle)
                                                        .foregroundStyle(.secondary)
                                                        .multilineTextAlignment(.center)
                                                        .lineSpacing(2)
                                                }
                                            }

                                            Spacer()
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(minHeight: geometry.size.height)
                                    } else {
                                        VStack(spacing: 0) {
                                            PowerModeConfigurationsGrid(
                                                powerModeManager: powerModeManager,
                                                onEditConfig: { config in
                                                    openPanel(mode: .edit(config))
                                                }
                                            )
                                            .padding(.horizontal, Spacing.group)
                                            .padding(.vertical, Spacing.group)

                                            Spacer()
                                                .frame(height: 40)
                                        }
                                    }
                                }
                            }
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.controlBackground)
            }
            .background(Color.controlBackground)
            .slidingPanel(isPresented: .init(
                get: { isPanelOpen },
                set: { if !$0 { closePanel() } }
            ), width: 400) {
                if let mode = configurationMode {
                    ConfigurationView(mode: mode, powerModeManager: powerModeManager, onDismiss: closePanel)
                        .id(panelID)
                }
            }
            .slidingPanel(isPresented: .init(
                get: { isReorderPanelOpen },
                set: { if !$0 { closeReorderPanel() } }
            ), width: 400) {
                ReorderPanelView(powerModeManager: powerModeManager, onDismiss: closeReorderPanel)
            }
    }

    private func openPanel(mode: ConfigurationMode) {
        configurationMode = mode
        panelID = UUID()
        withAnimation(.smooth(duration: 0.3)) {
            isPanelOpen = true
        }
    }

    private func closePanel() {
        withAnimation(.smooth(duration: 0.3)) {
            isPanelOpen = false
            configurationMode = nil
        }
    }

    private func openReorderPanel() {
        withAnimation(.smooth(duration: 0.3)) {
            isReorderPanelOpen = true
        }
    }

    private func closeReorderPanel() {
        withAnimation(.smooth(duration: 0.3)) {
            isReorderPanelOpen = false
        }
    }
}

struct ReorderPanelView: View {
    @ObservedObject var powerModeManager: PowerModeManager
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: Spacing.comfy) {
                Text("Reorder Power Modes")
                    .font(.sectionHeader)
                    .foregroundStyle(.primary)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.rowSubtitle)
                        .foregroundStyle(.secondary)
                        .padding(Spacing.standard)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Circle())
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Close")
            }
            .padding(.horizontal, Spacing.group)
            .padding(.vertical, Spacing.section)
            .background(Color.windowBackground)
            .overlay(Divider().opacity(0.5), alignment: .bottom)

            // Reorder list
            List {
                ForEach(powerModeManager.configurations) { config in
                    HStack(spacing: Spacing.comfy) {
                        Image(systemName: "line.3.horizontal")
                            .font(.rowSubtitle)
                            .foregroundStyle(.secondary)

                        ZStack {
                            Circle()
                                .fill(Color.controlBackground)
                                .frame(width: 36, height: 36)
                            Text(config.emoji)
                                .font(.rowTitle)
                        }

                        Text(config.name)
                            .font(.rowTitle.weight(.medium))

                        Spacer()

                        HStack(spacing: Spacing.standard) {
                            if config.isDefault {
                                Text("Default")
                                    .font(.rowDetail)
                                    .padding(.horizontal, Spacing.standard)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.accentColor))
                                    .foregroundStyle(.primary)
                            }
                            if !config.isEnabled {
                                Text("Disabled")
                                    .font(.rowDetail)
                                    .padding(.horizontal, Spacing.standard)
                                    .padding(.vertical, Spacing.tight)
                                    .background(Capsule().fill(Color.controlBackground))
                                    .overlay(
                                        Capsule().stroke(Color.separatorColor, lineWidth: 0.5)
                                    )
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, Spacing.standard)
                    .padding(.horizontal, Spacing.comfy)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.controlBackground)
                    )
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .onMove(perform: powerModeManager.moveConfigurations)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .padding(.top, Spacing.standard)
        }
        .background(Color.windowBackground)
    }
}


struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.sectionHeader)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, Spacing.standard)
    }
}
