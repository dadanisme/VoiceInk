import SwiftUI
import Combine
import AppKit

struct FluidAudioModelCardRowView: View {
    let model: FluidAudioModel
    @ObservedObject var fluidAudioModelManager: FluidAudioModelManager
    @ObservedObject var transcriptionModelManager: TranscriptionModelManager
    @AppStorage("parakeet-streaming-enabled") private var streamingEnabled = true
    @AppStorage("nemotron-chunk-size-ms") private var nemotronChunkMs: Int = FluidAudioModelManager.defaultNemotronChunkMs
    @AppStorage("parakeet-eou-chunk-size-ms") private var parakeetEouChunkMs: Int = FluidAudioModelManager.defaultParakeetEouChunkMs

    var isCurrent: Bool {
        transcriptionModelManager.currentTranscriptionModel?.name == model.name
    }

    var isDownloaded: Bool {
        fluidAudioModelManager.isFluidAudioModelDownloaded(model)
    }

    var isDownloading: Bool {
        fluidAudioModelManager.isFluidAudioModelDownloading(model)
    }

    var body: some View {
        SurfaceCard(style: isCurrent ? .selected : .plain) {
            HStack(alignment: .top, spacing: Spacing.section) {
                VStack(alignment: .leading, spacing: Spacing.standard) {
                    headerSection
                    metadataSection
                    descriptionSection
                    if model.family == .nemotronStreaming || model.family == .parakeetEou {
                        chunkSizePicker
                            .padding(.top, Spacing.tight)
                    }
                    progressSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)

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
            if model.family == .nemotronStreaming || model.family == .parakeetEou {
                Text("Real-time only")
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, Spacing.standard)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(Capsule())
            }
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
            Label(model.language, systemImage: "globe")
            Label(model.size, systemImage: "internaldrive")
            HStack(spacing: 3) {
                Text("Speed")
                progressDotsWithNumber(value: model.speed * 10)
            }
            .fixedSize(horizontal: true, vertical: false)
            HStack(spacing: 3) {
                Text("Accuracy")
                progressDotsWithNumber(value: model.accuracy * 10)
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .font(.rowDetail)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.tight) {
            Text(model.description)
                .font(.rowDetail)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            if model.family == .nemotronStreaming || model.family == .parakeetEou {
                Text("Batch transcription (saved recordings) falls back to Parakeet V3.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, Spacing.tight)
    }

    @ViewBuilder
    private var chunkSizePicker: some View {
        HStack(spacing: Spacing.standard) {
            Text("Chunk size")
                .font(.caption)
                .foregroundStyle(.secondary)

            switch model.family {
            case .nemotronStreaming:
                Picker("", selection: $nemotronChunkMs) {
                    ForEach(FluidAudioModelManager.allowedNemotronChunkMs, id: \.self) { ms in
                        Text("\(ms) ms").tag(ms)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)

            case .parakeetEou:
                Picker("", selection: $parakeetEouChunkMs) {
                    ForEach(FluidAudioModelManager.allowedParakeetEouChunkMs, id: \.self) { ms in
                        Text("\(ms) ms").tag(ms)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)

            case .parakeetTdt:
                EmptyView()
            }

            Spacer()
        }
    }

    private var progressSection: some View {
        Group {
            if isDownloading {
                let progress = fluidAudioModelManager.downloadProgress(for: model) ?? 0.0
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, Spacing.standard)
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
                Button(action: {
                    Task {
                        transcriptionModelManager.setDefaultTranscriptionModel(model)
                    }
                }) {
                    Text("Set as Default")
                        .font(.rowSubtitle)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else {
                Button(action: {
                    Task {
                        await fluidAudioModelManager.downloadFluidAudioModel(model)
                    }
                }) {
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
                    Button(action: {
                        fluidAudioModelManager.deleteFluidAudioModel(model)
                    }) {
                        Label("Delete Model", systemImage: "trash")
                    }

                    Button {
                        fluidAudioModelManager.showFluidAudioModelInFinder(model)
                    } label: {
                        Label("Show in Finder", systemImage: "folder")
                    }

                    Button {
                        streamingEnabled.toggle()
                    } label: {
                        Label(streamingEnabled ? "Disable Live Streaming" : "Enable Live Streaming", systemImage: streamingEnabled ? "waveform.slash" : "waveform")
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
