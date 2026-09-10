import StoreKit
import SwiftUI

struct SubscriptionPaywallView: View {
    @EnvironmentObject private var subscription: SubscriptionManager

    private let privacyURL = URL(string: "https://nickvan23-lang.github.io/signal-scout/privacy.html")!
    private let supportURL = URL(string: "https://nickvan23-lang.github.io/signal-scout/support.html")!
    private let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private let manageURL = URL(string: "https://apps.apple.com/account/subscriptions")!

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Spacer(minLength: 24)

                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 54, weight: .semibold))
                    .foregroundStyle(ScoutPalette.cyan)
                    .frame(width: 108, height: 108)
                    .background(ScoutPalette.cyan.opacity(0.14), in: Circle())
                    .shadow(color: ScoutPalette.cyan.opacity(0.28), radius: 22)

                VStack(spacing: 8) {
                    Text(subscription.access == .locked ? "Your preview has ended" : "Signal Scout Pro")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .multilineTextAlignment(.center)
                    Text("Find advertising Bluetooth signals with a live field map and focused warmer-and-colder guidance.")
                        .font(.body)
                        .foregroundStyle(ScoutPalette.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 15) {
                    PaywallFeature(icon: "scope", title: "Live signal field", detail: "Map every visible anonymous BLE signal by relative strength.")
                    PaywallFeature(icon: "arrow.up.left.and.arrow.down.right", title: "Full-screen map", detail: "Pan, zoom, and tap any signal to track it.")
                    PaywallFeature(icon: "flame", title: "Warmer and colder", detail: "Use smoothed trends, charts, and haptics while you walk.")
                    PaywallFeature(icon: "hand.raised", title: "Private by design", detail: "No device names, accounts, analytics, ads, location, or network uploads.")
                }
                .padding(18)
                .background(ScoutPalette.panel, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                if subscription.access == .previewAvailable {
                    Button {
                        subscription.startPreview()
                    } label: {
                        Text("Start 60-Second Free Preview")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(.bordered)
                    .tint(ScoutPalette.cyan)

                    Text("The preview starts only when you tap. No purchase is required and no charge occurs.")
                        .font(.caption)
                        .foregroundStyle(ScoutPalette.secondary)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task { await subscription.purchaseMonthly() }
                } label: {
                    HStack {
                        if subscription.isPurchasing {
                            ProgressView().tint(ScoutPalette.background)
                        }
                        Text(purchaseButtonTitle)
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, minHeight: 54)
                }
                .buttonStyle(.borderedProminent)
                .tint(ScoutPalette.cyan)
                .foregroundStyle(ScoutPalette.background)
                .disabled(subscription.monthlyProduct == nil || subscription.isPurchasing)

                if subscription.monthlyProduct == nil {
                    Button("Retry App Store") {
                        Task { await subscription.loadProducts() }
                    }
                    .font(.subheadline.bold())
                }

                if let message = subscription.message {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(ScoutPalette.amber)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button("Restore Purchases") {
                    Task { await subscription.restorePurchases() }
                }
                .font(.subheadline.bold())
                .disabled(subscription.isPurchasing)

                if subscription.access == .locked {
                    Link("Manage Subscription", destination: manageURL)
                        .font(.subheadline)
                }

                Text(subscriptionDisclosure)
                    .font(.caption2)
                    .foregroundStyle(ScoutPalette.secondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 18) {
                    Link("Privacy", destination: privacyURL)
                    Link("Support", destination: supportURL)
                    Link("Terms", destination: termsURL)
                }
                .font(.caption.bold())

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 22)
        }
        .background(ScoutPalette.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .task {
            if subscription.monthlyProduct == nil {
                await subscription.loadProducts()
            }
        }
    }

    private var purchaseButtonTitle: String {
        if let product = subscription.monthlyProduct {
            return "Subscribe — \(product.displayPrice) per month"
        }
        return "Loading App Store Price…"
    }

    private var subscriptionDisclosure: String {
        "Payment is charged to your Apple Account at confirmation. The subscription renews automatically each month unless canceled at least 24 hours before the current period ends. Your account is charged for renewal within 24 hours before the period ends. Manage or cancel in App Store account settings."
    }
}

private struct PaywallFeature: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(ScoutPalette.cyan)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(ScoutPalette.secondary)
            }
        }
    }
}
