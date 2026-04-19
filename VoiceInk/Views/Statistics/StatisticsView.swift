import SwiftUI
import SwiftData
import os

struct StatisticsView: View {
    private let logger = Logger(subsystem: "com.prakashjoshipax.VoiceInk", category: "StatisticsView")
    @Environment(\.modelContext) private var modelContext

    @State private var totalCount: Int = 0
    @State private var totalWords: Int = 0
    @State private var totalDuration: TimeInterval = 0
    @State private var isLoading: Bool = true
    @State private var loadTask: Task<Void, Never>?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading statistics…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if totalCount == 0 {
                emptyStateView
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 240), spacing: 16)],
                        spacing: 16
                    ) {
                        MetricCard(
                            icon: "mic.fill",
                            title: "Sessions Recorded",
                            value: "\(totalCount)",
                            detail: "completed transcriptions",
                            color: .purple
                        )
                        MetricCard(
                            icon: "text.alignleft",
                            title: "Words Dictated",
                            value: formattedNumber(totalWords),
                            detail: "words generated",
                            color: Color(nsColor: .controlAccentColor)
                        )
                        MetricCard(
                            icon: "clock.fill",
                            title: "Time Recorded",
                            value: formattedDuration(totalDuration),
                            detail: "across all sessions",
                            color: .orange
                        )
                    }
                    .padding(.vertical, 28)
                    .padding(.horizontal, 32)
                }
                .background(Color(.windowBackgroundColor))
            }
        }
        .task {
            await reload()
        }
        .onReceive(NotificationCenter.default.publisher(for: .transcriptionCreated)) { _ in
            scheduleReload()
        }
        .onReceive(NotificationCenter.default.publisher(for: .transcriptionCompleted)) { _ in
            scheduleReload()
        }
        .onReceive(NotificationCenter.default.publisher(for: .transcriptionDeleted)) { _ in
            scheduleReload()
        }
        .onDisappear {
            loadTask?.cancel()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48, weight: .regular))
                .foregroundColor(.secondary)
            Text("No Transcriptions Yet")
                .font(.title3.weight(.semibold))
            Text("Statistics will appear here after your first recording.")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }

    private func scheduleReload() {
        loadTask?.cancel()
        loadTask = Task { await reload() }
    }

    private func reload() async {
        await MainActor.run { self.isLoading = true }

        let backgroundContext = ModelContext(modelContext.container)

        do {
            let completedFilter = #Predicate<Transcription> { $0.transcriptionStatus == "completed" }
            let count = try backgroundContext.fetchCount(FetchDescriptor<Transcription>(predicate: completedFilter))

            guard !Task.isCancelled else {
                await MainActor.run { self.isLoading = false }
                return
            }

            var descriptor = FetchDescriptor<Transcription>(predicate: completedFilter)
            descriptor.propertiesToFetch = [\.text, \.duration]

            var words = 0
            var duration: TimeInterval = 0
            try backgroundContext.enumerate(descriptor) { transcription in
                words += transcription.text.split(whereSeparator: \.isWhitespace).count
                duration += transcription.duration
            }

            guard !Task.isCancelled else {
                await MainActor.run { self.isLoading = false }
                return
            }

            await MainActor.run {
                self.totalCount = count
                self.totalWords = words
                self.totalDuration = duration
                self.isLoading = false
            }
        } catch {
            logger.error("Error loading statistics: \(error.localizedDescription, privacy: .public)")
            await MainActor.run { self.isLoading = false }
        }
    }

    private func formattedNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func formattedDuration(_ interval: TimeInterval) -> String {
        guard interval > 0 else { return "–" }
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = interval >= 3600 ? [.hour, .minute] : [.minute, .second]
        formatter.maximumUnitCount = 2
        return formatter.string(from: interval) ?? "–"
    }
}
