import SwiftUI

/// Compact panel-optimized performance analysis view for sliding panels and sidebars.
struct PerformanceAnalysisPanelView: View {
    let transcriptions: [Transcription]
    let onClose: () -> Void
    private let analysis: PerformanceAnalyzer.AnalysisResult

    init(transcriptions: [Transcription], onClose: @escaping () -> Void) {
        self.transcriptions = transcriptions
        self.onClose = onClose
        self.analysis = PerformanceAnalyzer.analyze(transcriptions: transcriptions)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, Spacing.section + 4)
                .padding(.vertical, Spacing.comfy)
                .background(Color.windowBackground)
                .overlay(Divider().opacity(0.5), alignment: .bottom)
                .zIndex(1)

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.section + 4) {
                    summarySection
                    systemInfoSection

                    if !analysis.transcriptionModels.isEmpty {
                        transcriptionModelsSection
                    }

                    if !analysis.enhancementModels.isEmpty {
                        enhancementModelsSection
                    }
                }
                .padding(Spacing.section)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Spacing.comfy) {
            Text("Performance Analysis")
                .font(.sectionHeader)
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.rowSubtitle.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(Spacing.tight + 2)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .help("Close performance analysis")
        }
    }

    // MARK: - Summary

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: Spacing.standard) {
            sectionHeader("Summary")

            HStack(spacing: Spacing.standard + 2) {
                summaryPill(icon: "doc.text.fill", value: "\(analysis.totalTranscripts)", label: "Total", color: .indigo)
                summaryPill(icon: "waveform.path.ecg", value: "\(analysis.totalWithTranscriptionData)", label: "Analyzable", color: .teal)
                summaryPill(icon: "sparkles", value: "\(analysis.totalEnhancedFiles)", label: "Enhanced", color: .mint)
            }
        }
    }

    private func summaryPill(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: Spacing.tight) {
            Image(systemName: icon)
                .font(.rowSubtitle.weight(.medium))
                .foregroundStyle(color)
            Text(value)
                .font(.titleEmphasis)
                .foregroundStyle(.primary)
            Text(label)
                .font(.rowDetail)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.standard + 2)
        .background(MetricCardBackground(color: color))
        .cornerRadius(10)
    }

    // MARK: - System Info

    private var systemInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.standard) {
            sectionHeader("System Information")

            VStack(spacing: 0) {
                infoRow(label: "Device", value: PerformanceAnalyzer.getMacModel())
                Divider().padding(.horizontal, Spacing.standard + 2)
                infoRow(label: "Processor", value: PerformanceAnalyzer.getCPUInfo())
                Divider().padding(.horizontal, Spacing.standard + 2)
                infoRow(label: "Memory", value: PerformanceAnalyzer.getMemoryInfo())
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.controlBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.labelQuaternary.opacity(0.3), lineWidth: 1)
                    )
            )
            .cornerRadius(10)
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.rowDetail.weight(.medium))
                .foregroundStyle(.secondary)
            Spacer(minLength: Spacing.tight)
            Text(value)
                .font(.rowDetail.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, Spacing.comfy)
        .padding(.vertical, Spacing.standard)
    }

    // MARK: - Transcription Models

    private let gridColumns = [
        GridItem(.flexible(), spacing: Spacing.comfy),
        GridItem(.flexible(), spacing: Spacing.comfy)
    ]

    private var transcriptionModelsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.standard + 2) {
            sectionHeader("Transcription Models")

            LazyVGrid(columns: gridColumns, spacing: Spacing.comfy) {
                ForEach(analysis.transcriptionModels) { modelStat in
                    transcriptionModelTile(modelStat)
                }
            }
        }
    }

    private func transcriptionModelTile(_ modelStat: PerformanceAnalyzer.ModelStat) -> some View {
        VStack(spacing: Spacing.standard + 2) {
            // Model name + count
            VStack(spacing: 2) {
                Text(modelStat.name)
                    .font(.rowDetail.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("\(modelStat.fileCount) transcripts")
                    .font(.rowDetail)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            // Hero metric
            VStack(spacing: 3) {
                Text(String(format: "%.1fx", modelStat.speedFactor))
                    .font(.largeTitle)
                    .foregroundColor(.mint)
                Text("Faster than Real-time")
                    .font(.rowDetail)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .padding(.horizontal, Spacing.standard)

            // Secondary metrics
            HStack(spacing: 0) {
                VStack(spacing: 2) {
                    Text(formatDuration(modelStat.avgAudioDuration))
                        .font(Font.system(.footnote, design: .monospaced).weight(.semibold))
                        .foregroundColor(.indigo)
                    Text("Avg. Audio")
                        .font(.rowDetail)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color.separatorColor)
                    .frame(width: 1, height: 24)

                VStack(spacing: 2) {
                    Text(String(format: "%.2fs", modelStat.avgProcessingTime))
                        .font(Font.system(.footnote, design: .monospaced).weight(.semibold))
                        .foregroundColor(.teal)
                    Text("Avg. Processing")
                        .font(.rowDetail)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(Spacing.section - 2)
        .background(MetricCardBackground(color: .mint))
        .cornerRadius(12)
    }

    // MARK: - Enhancement Models

    private var enhancementModelsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.standard + 2) {
            sectionHeader("Enhancement Models")

            LazyVGrid(columns: gridColumns, spacing: Spacing.comfy) {
                ForEach(analysis.enhancementModels) { modelStat in
                    enhancementModelTile(modelStat)
                }
            }
        }
    }

    private func enhancementModelTile(_ modelStat: PerformanceAnalyzer.ModelStat) -> some View {
        VStack(spacing: Spacing.standard + 2) {
            // Model name + count
            VStack(spacing: 2) {
                Text(modelStat.name)
                    .font(.rowDetail.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("\(modelStat.fileCount) transcripts")
                    .font(.rowDetail)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            // Hero metric
            VStack(spacing: 3) {
                Text(String(format: "%.2f s", modelStat.avgProcessingTime))
                    .font(.largeTitle)
                    .foregroundColor(.indigo)
                Text("Avg. Enhancement Time")
                    .font(.rowDetail)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Spacing.section - 2)
        .background(MetricCardBackground(color: .indigo))
        .cornerRadius(12)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.rowDetail.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.5)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0s"
    }
}
