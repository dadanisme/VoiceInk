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
                        glowColor: .accentColor,
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
                        glowColor: .accentColor,
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
    let glowColor: Color
    let actionTitle: String
    let actionIcon: String
    let action: () -> Void
    var onDismiss: (() -> Void)? = nil

    private static let defaultGradient: LinearGradient = LinearGradient(
        colors: [
            Color.accentColor,
            Color.accentColor.opacity(0.6)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: Spacing.section) {
                // TODO HIG: contrast over branded fill
                Text(badge.uppercased())
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(0.8)
                    .padding(.horizontal, Spacing.comfy)
                    .padding(.vertical, Spacing.tight + 2)
                    .background(.white.opacity(0.2))
                    .clipShape(Capsule())
                    .foregroundColor(.white)

                // TODO HIG: contrast over branded fill
                Text(title)
                    .font(.titleEmphasis)
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)

                // TODO HIG: contrast over branded fill
                Text(message)
                    .font(.rowSubtitle)
                    .foregroundColor(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: action) {
                    HStack(spacing: Spacing.tight + 2) {
                        Text(actionTitle)
                        Image(systemName: actionIcon)
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, Spacing.section)
                    .padding(.vertical, Spacing.standard + 1)
                    .background(.white.opacity(0.22))
                    .clipShape(Capsule())
                    // TODO HIG: contrast over branded fill
                    .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
            .padding(Spacing.section + 2)
            .frame(maxWidth: .infinity, alignment: .topLeading)

            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    // TODO HIG: contrast over branded fill
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .padding(Spacing.comfy)
                .help("Dismiss this promotion")
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Self.defaultGradient)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: glowColor.opacity(0.15), radius: 12, x: 0, y: 8)
    }
}
