import SwiftUI

struct NativeSidebarRow: View {
    let title: String
    let systemImage: String
    var help: String? = nil

    var body: some View {
        Label(title, systemImage: systemImage)
            .labelStyle(.titleAndIcon)
            .help(help ?? title)
    }
}
