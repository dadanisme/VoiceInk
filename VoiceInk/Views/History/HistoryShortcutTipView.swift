import SwiftUI
import KeyboardShortcuts

struct HistoryShortcutTipView: View {
    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: Spacing.comfy) {
                HStack(spacing: Spacing.comfy) {
                    Image(systemName: "command.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 24, height: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Quick Access")
                            .font(.sectionHeader)
                        Text("Open history from anywhere with a global shortcut")
                            .font(.rowSubtitle)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()
                    .padding(.vertical, Spacing.tight)

                HStack(spacing: Spacing.comfy) {
                    Text("Open History Window")
                        .font(.rowSubtitle)
                        .foregroundStyle(.secondary)

                    KeyboardShortcuts.Recorder(for: .openHistoryWindow)
                        .controlSize(.small)

                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
