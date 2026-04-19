import SwiftUI

struct PowerModePopover: View {
    @ObservedObject var powerModeManager = PowerModeManager.shared
    @State private var selectedConfig: PowerModeConfig?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.standard) {
            Text("Select Power Mode")
                .font(.sectionHeader)
                .foregroundStyle(.primary)
                .padding(.horizontal)
                .padding(.top, Spacing.standard)

            Divider()

            ScrollView {
                let enabledConfigs = powerModeManager.configurations.filter { $0.isEnabled }
                VStack(alignment: .leading, spacing: Spacing.tight) {
                    if enabledConfigs.isEmpty {
                        VStack(alignment: .center, spacing: Spacing.standard) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.secondary)
                                .font(.rowTitle)
                            Text("No Power Modes Available")
                                .foregroundStyle(.secondary)
                                .font(.rowSubtitle)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.section)
                    } else {
                        ForEach(enabledConfigs) { config in
                            PowerModeRow(
                                config: config,
                                isSelected: selectedConfig?.id == config.id,
                                action: {
                                    powerModeManager.setActiveConfiguration(config)
                                    selectedConfig = config
                                    applySelectedConfiguration()
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(width: 180)
        .frame(maxHeight: 340)
        .padding(.vertical, Spacing.standard)
        .background(Color.windowBackground)
        .onAppear {
            selectedConfig = powerModeManager.activeConfiguration
        }
        .onChange(of: powerModeManager.activeConfiguration) { newValue in
            selectedConfig = newValue
        }
    }

    private func applySelectedConfiguration() {
        Task {
            if let config = selectedConfig {
                await PowerModeSessionManager.shared.beginSession(with: config)
            }
        }
    }
}

struct PowerModeRow: View {
    let config: PowerModeConfig
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.standard) {
                Text(config.emoji)
                    .font(.rowSubtitle)

                Text(config.name)
                    .foregroundStyle(.primary)
                    .font(.rowSubtitle)
                    .lineLimit(1)

                if isSelected {
                    Spacer()
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                        .font(.rowDetail)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Spacing.tight)
            .padding(.horizontal, Spacing.standard)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        .cornerRadius(4)
    }
}
