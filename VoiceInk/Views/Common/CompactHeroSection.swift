import SwiftUI

struct CompactHeroSection: View {
    let icon: String
    let title: String
    let description: String
    var maxDescriptionWidth: CGFloat? = nil

    var body: some View {
        VStack(spacing: Spacing.section) {
            // HIG: decorative — size is layout-critical, not typography
            Image(systemName: icon)
                .font(.system(size: 28, weight: .regular, design: .default))
                .foregroundStyle(.blue)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: Spacing.standard) {
                Text(title)
                    .font(.titleEmphasis)
                Text(description)
                    .font(.rowSubtitle)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: maxDescriptionWidth)
            }
        }
        .padding(.vertical, Spacing.group)
        .frame(maxWidth: .infinity)
    }
}
