import SwiftUI

struct SurfaceCard<Content: View>: View {
    enum Style {
        case plain
        case material
        case selected
    }

    var style: Style = .plain
    var cornerRadius: CGFloat = 10
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(Spacing.section)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.separatorColor.opacity(0.6), lineWidth: 0.5)
            )
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .plain:
            Color.controlBackground
        case .material:
            Rectangle().fill(.regularMaterial)
        case .selected:
            Color.accentColor.opacity(0.15)
        }
    }
}
