import SwiftUI
import AppKit

// MARK: - Custom Model Card View
struct CustomModelCardView: View {
    let model: CustomCloudModel
    let isCurrent: Bool
    var setDefaultAction: () -> Void
    var deleteAction: () -> Void
    var editAction: (CustomCloudModel) -> Void

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
            }
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
            } else {
                Text("Custom")
                    .font(.rowDetail)
                    .fontWeight(.medium)
                    .padding(.horizontal, Spacing.standard)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.accentColor.opacity(0.2)))
                    .foregroundStyle(Color.accentColor)
            }
        }
    }

    private var metadataSection: some View {
        HStack(spacing: Spacing.comfy) {
            // Provider
            Label("Custom Provider", systemImage: "cloud")
                .font(.rowDetail)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            // Language
            Label(model.language, systemImage: "globe")
                .font(.rowDetail)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            // OpenAI Compatible
            Label("OpenAI Compatible", systemImage: "checkmark.seal")
                .font(.rowDetail)
                .foregroundStyle(.secondary)
                .lineLimit(1)
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
            } else {
                Button(action: setDefaultAction) {
                    Text("Set as Default")
                        .font(.rowSubtitle)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Menu {
                Button {
                    editAction(model)
                } label: {
                    Label("Edit Model", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    deleteAction()
                } label: {
                    Label("Delete Model", systemImage: "trash")
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
