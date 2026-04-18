import SwiftUI

struct MetricCard: View {
    let icon: String
    let title: String
    let value: String
    let detail: String?
    let color: Color

    var body: some View {
        SurfaceCard(style: .material, cornerRadius: 16) {
            VStack(alignment: .leading, spacing: Spacing.comfy) {
                HStack(alignment: .center, spacing: Spacing.comfy) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(color.opacity(0.15))
                        Image(systemName: icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundColor(color)
                    }
                    .frame(width: 34, height: 34)

                    Text(title)
                        .font(.sectionHeader)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Text(value)
                    .font(.largeTitle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                if let detail, !detail.isEmpty {
                    Text(detail)
                        .font(.rowDetail)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}
