import SwiftUI
import AppKit
// MARK: - Local Model Card View
struct LocalModelCardView: View {
    let model: LocalModel
    let isDownloaded: Bool
    let isCurrent: Bool
    let downloadProgress: [String: Double]
    let modelURL: URL?
    let isWarming: Bool

    // Actions
    var deleteAction: () -> Void
    var setDefaultAction: () -> Void
    var downloadAction: () -> Void
    private var isDownloading: Bool {
        downloadProgress.keys.contains(model.name + "_main") ||
        downloadProgress.keys.contains(model.name + "_coreml")
    }

    var body: some View {
        SurfaceCard(style: isCurrent ? .selected : .plain) {
            HStack(alignment: .top, spacing: Spacing.section) {
                // Main Content
                VStack(alignment: .leading, spacing: Spacing.standard) {
                    headerSection
                    metadataSection
                    descriptionSection
                    progressSection
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
            } else if isDownloaded {
                Text("Downloaded")
                    .font(.rowDetail)
                    .fontWeight(.medium)
                    .padding(.horizontal, Spacing.standard)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.labelQuaternary))
                    .foregroundStyle(.primary)
            }
        }
    }

    private var metadataSection: some View {
        HStack(spacing: Spacing.comfy) {
            // Language
            Label(model.language, systemImage: "globe")
                .font(.rowDetail)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            // Size
            Label(model.size, systemImage: "internaldrive")
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

    private var progressSection: some View {
        Group {
            if isDownloading {
                DownloadProgressView(
                    modelName: model.name,
                    downloadProgress: downloadProgress
                )
                .padding(.top, Spacing.standard)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var actionSection: some View {
        HStack(spacing: Spacing.standard) {
            if isCurrent {
                Text("Default Model")
                    .font(.rowSubtitle)
                    .foregroundStyle(.secondary)
            } else if isDownloaded {
                if isWarming {
                    HStack(spacing: Spacing.standard) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Optimizing model for your device...")
                            .font(.rowSubtitle)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Button(action: setDefaultAction) {
                        Text("Set as Default")
                            .font(.rowSubtitle)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            } else {
                Button(action: downloadAction) {
                    HStack(spacing: Spacing.tight) {
                        Text(isDownloading ? "Downloading..." : "Download")
                        Image(systemName: "arrow.down.circle")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(isDownloading)
            }

            if isDownloaded {
                Menu {
                    Button(action: deleteAction) {
                        Label("Delete Model", systemImage: "trash")
                    }

                    Button {
                        if let modelURL = modelURL {
                            NSWorkspace.shared.selectFile(modelURL.path, inFileViewerRootedAtPath: "")
                        }
                    } label: {
                        Label("Show in Finder", systemImage: "folder")
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
}

// MARK: - Imported Local Model (minimal UI)
struct ImportedLocalModelCardView: View {
    let model: ImportedLocalModel
    let isDownloaded: Bool
    let isCurrent: Bool
    let modelURL: URL?

    var deleteAction: () -> Void
    var setDefaultAction: () -> Void

    var body: some View {
        SurfaceCard(style: isCurrent ? .selected : .plain) {
            HStack(alignment: .top, spacing: Spacing.section) {
                VStack(alignment: .leading, spacing: Spacing.standard) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(model.displayName)
                            .font(.rowTitle)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        if isCurrent {
                            Text("Default")
                                .font(.rowDetail)
                                .fontWeight(.medium)
                                .padding(.horizontal, Spacing.standard)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.accentColor))
                                .foregroundStyle(.primary)
                        } else if isDownloaded {
                            Text("Imported")
                                .font(.rowDetail)
                                .fontWeight(.medium)
                                .padding(.horizontal, Spacing.standard)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.labelQuaternary))
                                .foregroundStyle(.primary)
                        }
                        Spacer()
                    }

                    Text("Imported local model")
                        .font(.rowDetail)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Spacing.tight)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: Spacing.standard) {
                    if isCurrent {
                        Text("Default Model")
                            .font(.rowSubtitle)
                            .foregroundStyle(.secondary)
                    } else if isDownloaded {
                        Button(action: setDefaultAction) {
                            Text("Set as Default")
                                .font(.rowSubtitle)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    if isDownloaded {
                        Menu {
                            Button(action: deleteAction) {
                                Label("Delete Model", systemImage: "trash")
                            }
                            Button {
                                if let modelURL = modelURL {
                                    NSWorkspace.shared.selectFile(modelURL.path, inFileViewerRootedAtPath: "")
                                }
                            } label: {
                                Label("Show in Finder", systemImage: "folder")
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
        }
    }
}


// MARK: - Helper Views and Functions

func progressDotsWithNumber(value: Double) -> some View {
    HStack(spacing: Spacing.tight) {
        progressDots(value: value)
        Text(String(format: "%.1f", value))
            .font(Font.system(.caption2, design: .monospaced).weight(.medium))
            .foregroundStyle(.secondary)
    }
}

func progressDots(value: Double) -> some View {
    HStack(spacing: 2) {
        ForEach(0..<5) { index in
            Circle()
                .fill(index < Int(value / 2) ? performanceColor(value: value / 10) : Color.labelQuaternary)
                .frame(width: 6, height: 6)
        }
    }
}

func performanceColor(value: Double) -> Color {
    switch value {
    case 0.8...1.0: return Color(.systemGreen)
    case 0.6..<0.8: return Color(.systemYellow)
    case 0.4..<0.6: return Color(.systemOrange)
    default: return Color(.systemRed)
    }
}
