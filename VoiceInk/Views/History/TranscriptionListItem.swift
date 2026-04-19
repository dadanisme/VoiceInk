import SwiftUI

struct TranscriptionListItem: View {
    let transcription: Transcription
    let isSelected: Bool
    let isChecked: Bool
    let onSelect: () -> Void
    let onToggleCheck: () -> Void

    var body: some View {
        HStack(spacing: Spacing.standard) {
            Toggle("", isOn: Binding(
                get: { isChecked },
                set: { _ in onToggleCheck() }
            ))
            .toggleStyle(CircularCheckboxStyle())
            .labelsHidden()

            VStack(alignment: .leading, spacing: Spacing.tight) {
                HStack {
                    Text(transcription.timestamp, format: .dateTime.month(.abbreviated).day().hour().minute())
                        .font(.rowDetail)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if transcription.duration > 0 {
                        Text(transcription.duration.formatTiming())
                            .font(.rowDetail)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(Color.secondary.opacity(0.1))
                            )
                            .foregroundStyle(.secondary)
                    }
                }

                Text(transcription.enhancedText ?? transcription.text)
                    .font(.rowSubtitle)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
            }
        }
        .padding(Spacing.standard)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.accentColor.opacity(0.15))
            } else {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.thinMaterial)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
    }
}

struct CircularCheckboxStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            // TODO HIG: icon sizing
            Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(configuration.isOn ? Color.accentColor : Color.labelSecondary)
                .font(.system(size: 18))
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}
