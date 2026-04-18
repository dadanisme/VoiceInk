import SwiftUI

struct PredefinedPromptsView: View {
    let onSelect: (TemplatePrompt) -> Void

    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: Spacing.section), count: 2)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: Spacing.section) {
                ForEach(PromptTemplates.all, id: \.title) { template in
                    PredefinedTemplateButton(prompt: template) {
                        onSelect(template)
                    }
                }
            }
            .padding(.horizontal, Spacing.group)
            .padding(.vertical, Spacing.group)
        }
        .frame(minWidth: 410, idealWidth: 520, maxWidth: 570, maxHeight: 440)
    }
}

struct PredefinedTemplateButton: View {
    let prompt: TemplatePrompt
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SurfaceCard {
                VStack(alignment: .leading, spacing: Spacing.comfy) {
                    HStack(alignment: .center, spacing: Spacing.comfy) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.controlBackground)
                            .frame(width: 42, height: 42)
                            .overlay(
                                Image(systemName: prompt.icon)
                                    .font(.titleEmphasis)
                                    .foregroundStyle(.primary)
                            )

                        Text(prompt.title)
                            .font(.rowTitle)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Spacer(minLength: 0)
                    }

                    Text(prompt.description)
                        .font(.rowDetail)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}
