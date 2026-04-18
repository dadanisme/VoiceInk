import SwiftUI
import AppKit

// MARK: - Native Apple Model Card View
struct NativeAppleModelCardView: View {
    let model: NativeAppleModel
    let isCurrent: Bool
    var setDefaultAction: () -> Void

    var body: some View {
        SurfaceCard(style: isCurrent ? .selected : .plain) {
            HStack(alignment: .top, spacing: Spacing.section) {
                // Main Content
                VStack(alignment: .leading, spacing: Spacing.standard) {
                    headerSection
                    metadataSection
                    descriptionSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Action Controls
                actionSection
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
                Text("Built-in")
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
            // Native Apple
            Label("Native Apple", systemImage: "apple.logo")
                .font(.rowDetail)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            // Language
            Label(model.language, systemImage: "globe")
                .font(.rowDetail)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            // On-Device
            Label("On-Device", systemImage: "checkmark.shield")
                .font(.rowDetail)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            // Requires macOS 26+
            Label("macOS 26+", systemImage: "macbook")
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
        }
    }
}
