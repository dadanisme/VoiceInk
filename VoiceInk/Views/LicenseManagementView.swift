import SwiftUI

struct LicenseManagementView: View {
    @StateObject private var licenseViewModel = LicenseViewModel()
    @Environment(\.colorScheme) private var colorScheme
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Section
                heroSection

                // Main Content
                VStack(spacing: Spacing.page) {
                    if case .licensed = licenseViewModel.licenseState {
                        activatedContent
                    } else {
                        purchaseContent
                    }
                }
                .padding(Spacing.page)
            }
        }
        .background(Color.controlBackground)
    }
    
    private var heroSection: some View {
        VStack(spacing: Spacing.group) {
            // App Icon
            AppIconView()

            // Title Section
            VStack(spacing: Spacing.section) {
                HStack(spacing: Spacing.section) {
                    // TODO HIG: icon sizing
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.blue)

                    HStack(alignment: .lastTextBaseline, spacing: Spacing.standard) {
                        Text(licenseViewModel.licenseState == .licensed ? "VoiceInk Pro" : "Upgrade to Pro")
                            .font(.largeTitle)

                        Text("v\(appVersion)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, Spacing.tight)
                    }
                }

                Text(licenseViewModel.licenseState == .licensed ?
                     "Thank you for supporting VoiceInk" :
                     "Transcribe what you say to text instantly with AI")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if case .licensed = licenseViewModel.licenseState {
                    HStack(spacing: 40) {
                        Button {
                            if let url = URL(string: "https://github.com/Beingpax/VoiceInk/releases") {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            featureItem(icon: "list.bullet.clipboard.fill", title: "Changelog", color: .blue)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .help("Open changelog")

                        Button {
                            if let url = URL(string: "https://discord.gg/xryDy57nYD") {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            featureItem(icon: "bubble.left.and.bubble.right.fill", title: "Discord", color: .purple)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .help("Open Discord")

                        Button {
                            EmailSupport.openSupportEmail()
                        } label: {
                            featureItem(icon: "envelope.fill", title: "Email Support", color: .orange)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .help("Email support")

                        Button {
                            if let url = URL(string: "https://tryvoiceink.com/docs") {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            featureItem(icon: "book.fill", title: "Docs", color: .indigo)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .help("Open documentation")

                        Button {
                            if let url = URL(string: "https://buymeacoffee.com/beingpax") {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            animatedTipJarItem()
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .help("Open tip jar")
                    }
                    .padding(.top, Spacing.standard)
                }
            }
        }
        .padding(.vertical, 60)
    }
    
    private var purchaseContent: some View {
        VStack(spacing: 40) {
            // Purchase Card
            SurfaceCard {
                VStack(spacing: Spacing.group) {
                    // Lifetime Access Badge
                    HStack {
                        Image(systemName: "infinity.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                        Text("Buy Once, Own Forever")
                            .font(.headline)
                    }
                    .padding(.vertical, Spacing.standard)
                    .padding(.horizontal, Spacing.section)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(12)

                    // Purchase Button
                    Button(action: {
                        if let url = URL(string: "https://tryvoiceink.com/buy") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Text("Upgrade to VoiceInk Pro")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.comfy)
                    }
                    .buttonStyle(.borderedProminent)

                    // Features Grid
                    HStack(spacing: 40) {
                        featureItem(icon: "bubble.left.and.bubble.right.fill", title: "Priority Support", color: .purple)
                        featureItem(icon: "infinity.circle.fill", title: "Lifetime Access", color: .blue)
                        featureItem(icon: "arrow.up.circle.fill", title: "Free Updates", color: .green)
                        featureItem(icon: "macbook.and.iphone", title: "Multiple Devices", color: .orange)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }

            // License Activation
            SurfaceCard {
                VStack(spacing: Spacing.group) {
                    Text("Already have a license?")
                        .font(.headline)

                    HStack(spacing: Spacing.comfy) {
                        TextField("Enter your license key", text: $licenseViewModel.licenseKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                            .textCase(.uppercase)

                        Button(action: {
                            Task { await licenseViewModel.validateLicense() }
                        }) {
                            if licenseViewModel.isValidating {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Text("Activate")
                                    .frame(width: 80)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(licenseViewModel.isValidating)
                    }

                    if let message = licenseViewModel.validationMessage {
                        Text(message)
                            .foregroundStyle(.red)
                            .font(.callout)
                    }
                }
            }

            // Already Purchased Section
            SurfaceCard {
                VStack(spacing: Spacing.group) {
                    Text("Already purchased?")
                        .font(.headline)

                    HStack(spacing: Spacing.comfy) {
                        Text("Manage your license and device activations")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Button(action: {
                            if let url = URL(string: "https://polar.sh/beingpax/portal/request") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            Text("License Management Portal")
                                .frame(width: 180)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
    }
    
    private var activatedContent: some View {
        VStack(spacing: Spacing.page) {
            // Status Card
            SurfaceCard {
                VStack(spacing: Spacing.group) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                        Text("License Active")
                            .font(.headline)
                        Spacer()
                        Text("Active")
                            .font(.caption)
                            .padding(.horizontal, Spacing.comfy)
                            .padding(.vertical, Spacing.tight)
                            .background(Capsule().fill(.green))
                            .foregroundStyle(.white)
                    }

                    Divider()

                    if licenseViewModel.activationsLimit > 0 {
                        Text("This license can be activated on up to \(licenseViewModel.activationsLimit) devices")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("You can use VoiceInk Pro on all your personal devices")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Deactivation Card
            SurfaceCard {
                VStack(alignment: .leading, spacing: Spacing.section) {
                    Text("License Management")
                        .font(.headline)

                    Button(role: .destructive, action: {
                        licenseViewModel.removeLicense()
                    }) {
                        Label("Deactivate License", systemImage: "xmark.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.standard)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private func featureItem(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: Spacing.standard) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(color)

            Text(title)
                .font(.rowDetail)
                .foregroundStyle(.primary)
        }
    }

    @State private var heartPulse = false

    private func animatedTipJarItem() -> some View {
        HStack(spacing: Spacing.standard) {
            Image(systemName: "heart.fill")
                .font(.callout)
                .foregroundStyle(.pink)
                .scaleEffect(heartPulse ? 1.3 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 1.2)
                        .repeatForever(autoreverses: true),
                    value: heartPulse
                )
                .onAppear {
                    heartPulse = true
                }

            Text("Tip Jar")
                .font(.rowDetail)
                .foregroundStyle(.primary)
        }
    }
}


