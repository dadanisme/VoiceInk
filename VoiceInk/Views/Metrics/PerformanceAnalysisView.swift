import SwiftUI

// MARK: - Shared Analysis Logic

enum PanelMode {
    case info
    case analysis
}

struct PerformanceAnalyzer {
    struct AnalysisResult {
        let totalTranscripts: Int
        let totalWithTranscriptionData: Int
        let totalAudioDuration: TimeInterval
        let totalEnhancedFiles: Int
        let transcriptionModels: [ModelStat]
        let enhancementModels: [ModelStat]
    }

    struct ModelStat: Identifiable {
        let id = UUID()
        let name: String
        let fileCount: Int
        let totalProcessingTime: TimeInterval
        let avgProcessingTime: TimeInterval
        let avgAudioDuration: TimeInterval
        let speedFactor: Double
    }

    static func analyze(transcriptions: [Transcription]) -> AnalysisResult {
        let totalTranscripts = transcriptions.count
        let totalWithTranscriptionData = transcriptions.filter { $0.transcriptionDuration != nil }.count
        let totalAudioDuration = transcriptions.reduce(0) { $0 + $1.duration }
        let totalEnhancedFiles = transcriptions.filter { $0.enhancedText != nil && $0.enhancementDuration != nil }.count

        let transcriptionStats = processStats(
            for: transcriptions,
            modelNameKeyPath: \.transcriptionModelName,
            durationKeyPath: \.transcriptionDuration,
            audioDurationKeyPath: \.duration
        )

        let enhancementStats = processStats(
            for: transcriptions,
            modelNameKeyPath: \.aiEnhancementModelName,
            durationKeyPath: \.enhancementDuration
        )

        return AnalysisResult(
            totalTranscripts: totalTranscripts,
            totalWithTranscriptionData: totalWithTranscriptionData,
            totalAudioDuration: totalAudioDuration,
            totalEnhancedFiles: totalEnhancedFiles,
            transcriptionModels: transcriptionStats,
            enhancementModels: enhancementStats
        )
    }

    static func processStats(for transcriptions: [Transcription],
                             modelNameKeyPath: KeyPath<Transcription, String?>,
                             durationKeyPath: KeyPath<Transcription, TimeInterval?>,
                             audioDurationKeyPath: KeyPath<Transcription, TimeInterval>? = nil) -> [ModelStat] {

        let relevantTranscriptions = transcriptions.filter {
            $0[keyPath: modelNameKeyPath] != nil && $0[keyPath: durationKeyPath] != nil
        }

        let groupedByModel = Dictionary(grouping: relevantTranscriptions) {
            $0[keyPath: modelNameKeyPath] ?? "Unknown"
        }

        return groupedByModel.map { modelName, items in
            let fileCount = items.count
            let totalProcessingTime = items.reduce(0) { $0 + ($1[keyPath: durationKeyPath] ?? 0) }
            let avgProcessingTime = totalProcessingTime / Double(fileCount)

            let totalAudioDuration = items.reduce(0) { $0 + $1.duration }
            let avgAudioDuration = totalAudioDuration / Double(fileCount)

            var speedFactor = 0.0
            if let audioDurationKeyPath = audioDurationKeyPath, totalProcessingTime > 0 {
                speedFactor = totalAudioDuration / totalProcessingTime
            }

            return ModelStat(
                name: modelName,
                fileCount: fileCount,
                totalProcessingTime: totalProcessingTime,
                avgProcessingTime: avgProcessingTime,
                avgAudioDuration: avgAudioDuration,
                speedFactor: speedFactor
            )
        }.sorted { $0.avgProcessingTime < $1.avgProcessingTime }
    }

    static func getMacModel() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &machine, &size, nil, 0)
        return String(cString: machine)
    }

    static func getCPUInfo() -> String {
        var size = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        var buffer = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.brand_string", &buffer, &size, nil, 0)
        return String(cString: buffer)
    }

    static func getMemoryInfo() -> String {
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        return ByteCountFormatter.string(fromByteCount: Int64(totalMemory), countStyle: .memory)
    }
}

// MARK: - Sheet View (existing)

struct PerformanceAnalysisView: View {
    @Environment(\.dismiss) private var dismiss
    let transcriptions: [Transcription]
    private let analysis: PerformanceAnalyzer.AnalysisResult

    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 250), spacing: 16)
    ]

    init(transcriptions: [Transcription]) {
        self.transcriptions = transcriptions
        self.analysis = PerformanceAnalyzer.analyze(transcriptions: transcriptions)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.page) {
                    summarySection

                    systemInfoSection

                    if !analysis.transcriptionModels.isEmpty {
                        transcriptionPerformanceSection
                    }

                    if !analysis.enhancementModels.isEmpty {
                        enhancementPerformanceSection
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 550, idealWidth: 600, maxWidth: 700, minHeight: 600, idealHeight: 750, maxHeight: 900)
        .background(Color.windowBackground)
    }

    private var header: some View {
        HStack {
            Text("Performance Analysis")
                .font(.largeTitle)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
            .help("Close")
        }
    }

    private var summarySection: some View {
        HStack(spacing: Spacing.comfy) {
            SummaryCard(
                icon: "doc.text.fill",
                value: "\(analysis.totalTranscripts)",
                label: "Total Transcripts",
                color: .indigo
            )
            SummaryCard(
                icon: "waveform.path.ecg",
                value: "\(analysis.totalWithTranscriptionData)",
                label: "Analyzable",
                color: .teal
            )
            SummaryCard(
                icon: "sparkles",
                value: "\(analysis.totalEnhancedFiles)",
                label: "Enhanced",
                color: .mint
            )
        }
    }

    private var systemInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.section) {
            Text("System Information")
                .font(.titleEmphasis)
                .foregroundStyle(.primary)

            HStack(spacing: Spacing.comfy) {
                SystemInfoCard(label: "Device", value: PerformanceAnalyzer.getMacModel())
                SystemInfoCard(label: "Processor", value: PerformanceAnalyzer.getCPUInfo())
                SystemInfoCard(label: "Memory", value: PerformanceAnalyzer.getMemoryInfo())
            }
        }
    }

    private var transcriptionPerformanceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.section) {
            Text("Transcription Models")
                .font(.titleEmphasis)
                .foregroundStyle(.primary)

            LazyVGrid(columns: columns, spacing: Spacing.section) {
                ForEach(analysis.transcriptionModels) { modelStat in
                    TranscriptionModelCard(modelStat: modelStat)
                }
            }
        }
    }

    private var enhancementPerformanceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.section) {
            Text("Enhancement Models")
                .font(.titleEmphasis)
                .foregroundStyle(.primary)

            LazyVGrid(columns: columns, spacing: Spacing.section) {
                ForEach(analysis.enhancementModels) { modelStat in
                    EnhancementModelCard(modelStat: modelStat)
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0s"
    }
}

// MARK: - Subviews

struct SummaryCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.standard) {
            // HIG: decorative — size is layout-critical, not typography
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium, design: .default))
                .foregroundStyle(color)

            Text(value)
                .font(.titleEmphasis)
                .foregroundStyle(.primary)

            Text(label)
                .font(.rowDetail)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.section)
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(MetricCardBackground(color: color))
        .cornerRadius(12)
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.sectionHeader)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.rowTitle)
                .foregroundStyle(.primary)
        }
    }
}

struct SystemInfoCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.tight) {
            Text(label)
                .font(.rowDetail.weight(.medium))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Text(value)
                .font(.rowTitle.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.comfy)
        .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
        .background(MetricCardBackground(color: .secondary))
        .cornerRadius(12)
    }
}

struct TranscriptionModelCard: View {
    let modelStat: PerformanceAnalyzer.ModelStat

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.comfy) {
            // Model name and transcript count
            HStack(alignment: .firstTextBaseline) {
                Text(modelStat.name)
                    .font(.sectionHeader)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer()

                Text("\(modelStat.fileCount) transcripts")
                    .font(.rowSubtitle)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(spacing: Spacing.section) {
                // Main metric: Speed Factor
                VStack {
                    Text(String(format: "%.1fx", modelStat.speedFactor))
                        .font(.largeTitle)
                        .foregroundColor(.mint)
                    Text("Faster than Real-time")
                        .font(.rowDetail)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()

                // Secondary metrics
                HStack {
                    MetricDisplay(
                        title: "Avg. Audio",
                        value: formatDuration(modelStat.avgAudioDuration),
                        color: .indigo
                    )
                    Spacer()
                    MetricDisplay(
                        title: "Avg. Process Time",
                        value: String(format: "%.2f s", modelStat.avgProcessingTime),
                        color: .teal
                    )
                }
            }
        }
        .padding(Spacing.section)
        .background(MetricCardBackground(color: .mint))
        .cornerRadius(12)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0s"
    }
}

struct EnhancementModelCard: View {
    let modelStat: PerformanceAnalyzer.ModelStat

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.comfy) {
            // Model name and transcript count
            HStack(alignment: .firstTextBaseline) {
                Text(modelStat.name)
                    .font(.sectionHeader)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer()

                Text("\(modelStat.fileCount) transcripts")
                    .font(.rowSubtitle)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .center) {
                Text(String(format: "%.2f s", modelStat.avgProcessingTime))
                    .font(.largeTitle)
                    .foregroundColor(.indigo)
                Text("Avg. Enhancement Time")
                    .font(.rowDetail)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(Spacing.section)
        .background(MetricCardBackground(color: .indigo))
        .cornerRadius(12)
    }
}

struct MetricCardBackground: View {
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: color.opacity(0.15), location: 0),
                        .init(color: Color.windowBackground.opacity(0.1), location: 0.6)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.labelQuaternary.opacity(0.3),
                                Color.labelQuaternary.opacity(0.1)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 5, y: 3)
    }
}

struct MetricDisplay: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.tight) {
            Text(title)
                .font(.rowDetail)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            Text(value)
                .font(Font.system(.body, design: .monospaced).weight(.semibold))
                .foregroundColor(color)
        }
    }
}
