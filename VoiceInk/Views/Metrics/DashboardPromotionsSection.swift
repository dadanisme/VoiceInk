import SwiftUI
import AppKit

struct DashboardPromotionsSection: View {
    let licenseState: LicenseViewModel.LicenseState
    @State private var isAffiliatePromotionDismissed: Bool = UserDefaults.standard.affiliatePromotionDismissed

    private var shouldShowUpgradePromotion: Bool {
        switch licenseState {
        case .trial(let daysRemaining):
            return daysRemaining <= 3
        case .trialExpired:
            return true
        case .licensed:
            return false
        }
    }

    private var shouldShowAffiliatePromotion: Bool {
        if case .licensed = licenseState {
            return !isAffiliatePromotionDismissed
        }
        return false
    }
    
    private var shouldShowPromotions: Bool {
        shouldShowUpgradePromotion || shouldShowAffiliatePromotion
    }
    
    var body: some View {
        if shouldShowPromotions {
            HStack(alignment: .top, spacing: Spacing.section) {
                if shouldShowUpgradePromotion {
                    DashboardPromotionCard(
                        badge: "30% OFF",
                        title: "Unlock VoiceInk Pro For Less",
                        message: "Share VoiceInk on your socials, and instantly unlock a 30% discount on VoiceInk Pro.",
                        accentSymbol: "megaphone.fill",
                        actionTitle: "Share & Unlock",
                        actionIcon: "arrow.up.right",
                        action: openSocialShare
                    )
                    .frame(maxWidth: .infinity)
                }

                if shouldShowAffiliatePromotion {
                    DashboardPromotionCard(
                        badge: "AFFILIATE 30%",
                        title: "Earn With The VoiceInk Affiliate Program",
                        message: "Share VoiceInk with friends or your audience and receive 30% on every referral that upgrades.",
                        accentSymbol: "link.badge.plus",
                        actionTitle: "Explore Affiliate",
                        actionIcon: "arrow.up.right",
                        action: openAffiliateProgram,
                        onDismiss: dismissAffiliatePromotion
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            EmptyView()
        }
    }
    
    private func openSocialShare() {
        if let url = URL(string: "https://tryvoiceink.com/social-share") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func openAffiliateProgram() {
        if let url = URL(string: "https://tryvoiceink.com/affiliate") {
            NSWorkspace.shared.open(url)
        }
    }

    private func dismissAffiliatePromotion() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isAffiliatePromotionDismissed = true
        }
        UserDefaults.standard.affiliatePromotionDismissed = true
    }
}

private struct DashboardPromotionCard: View {
    let badge: String
    let title: String
    let message: String
    let accentSymbol: String
    let actionTitle: String
    let actionIcon: String
    let action: () -> Void
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        SurfaceCard(cornerRadius: 12) {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: Spacing.section) {
                    Text(badge.uppercased())
                        .font(.system(size: 11, weight: .heavy))
                        .tracking(0.8)
                        .padding(.horizontal, Spacing.comfy)
                        .padding(.vertical, Spacing.tight + 2)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                        .foregroundStyle(.white)

                    Text(title)
                        .font(.titleEmphasis)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(message)
                        .font(.rowSubtitle)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(action: action) {
                        HStack(spacing: Spacing.tight + 2) {
                            Text(actionTitle)
                            Image(systemName: actionIcon)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                if let onDismiss = onDismiss {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .help("Dismiss this promotion")
                }
            }
        }
    }
}
