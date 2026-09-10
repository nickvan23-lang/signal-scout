import Foundation
import StoreKit

enum SubscriptionAccess: Equatable {
    case loading
    case previewAvailable
    case preview(secondsRemaining: Int)
    case subscribed
    case locked
}

@MainActor
final class SubscriptionManager: ObservableObject {
    nonisolated static let monthlyProductID = "com.nicholasvandervelden.SignalScout.monthly"
    nonisolated static let previewDuration: TimeInterval = 60

    @Published private(set) var access: SubscriptionAccess = .loading
    @Published private(set) var monthlyProduct: Product?
    @Published private(set) var isPurchasing = false
    @Published private(set) var message: String?

    private let previewStartKey = "signalScout.preview.startedAt.v1"
    private let defaults: UserDefaults
    private var updatesTask: Task<Void, Never>?
    private var previewTimer: Timer?
    private var hasPrepared = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.refreshEntitlement()
                }
            }
        }
    }

    deinit {
        updatesTask?.cancel()
        previewTimer?.invalidate()
    }

    var hasFeatureAccess: Bool {
        switch access {
        case .preview, .subscribed: return true
        default: return false
        }
    }

    var isSubscribed: Bool { access == .subscribed }

    var previewSecondsRemaining: Int? {
        guard case .preview(let seconds) = access else { return nil }
        return seconds
    }

    nonisolated static func remainingPreviewSeconds(startedAt: TimeInterval, now: TimeInterval) -> Int {
        let elapsed = max(0, now - startedAt)
        return max(0, Int(ceil(previewDuration - elapsed)))
    }

    func prepare() async {
        guard !hasPrepared else { return }
        hasPrepared = true
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-SignalScoutScreenshotMode") {
            access = .preview(secondsRemaining: 60)
            return
        }
#endif
        async let productLoad: Void = loadProducts()
        await refreshEntitlement()
        _ = await productLoad
    }

    func loadProducts() async {
        do {
            monthlyProduct = try await Product.products(for: [Self.monthlyProductID]).first
            if monthlyProduct == nil {
                message = "The monthly subscription is not available from the App Store yet."
            } else if message == "The monthly subscription is not available from the App Store yet." {
                message = nil
            }
        } catch {
            message = "The App Store price could not be loaded. Check your connection and try again."
        }
    }

    func startPreview() {
        guard access == .previewAvailable else { return }
        defaults.set(Date().timeIntervalSince1970, forKey: previewStartKey)
        message = nil
        updatePreviewState()
    }

    func purchaseMonthly() async {
        guard let monthlyProduct else {
            await loadProducts()
            return
        }

        isPurchasing = true
        message = nil
        defer { isPurchasing = false }

        do {
            let result = try await monthlyProduct.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    message = "The App Store could not verify this purchase."
                    return
                }
                await transaction.finish()
                await refreshEntitlement()
            case .pending:
                message = "This purchase is pending approval or payment confirmation."
            case .userCancelled:
                break
            @unknown default:
                message = "The purchase did not complete. Please try again."
            }
        } catch {
            message = "The purchase could not be completed. Please try again."
        }
    }

    func restorePurchases() async {
        isPurchasing = true
        message = nil
        defer { isPurchasing = false }

        do {
            try await AppStore.sync()
            await refreshEntitlement()
            if !isSubscribed {
                message = "No active Signal Scout subscription was found for this Apple Account."
            }
        } catch {
            message = "Purchases could not be restored. Please try again."
        }
    }

    func refreshEntitlement() async {
        var activeSubscription = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.productID == Self.monthlyProductID,
                  transaction.revocationDate == nil else { continue }

            if let expirationDate = transaction.expirationDate {
                activeSubscription = expirationDate > Date()
            } else {
                activeSubscription = true
            }
            if activeSubscription { break }
        }

        if activeSubscription {
            previewTimer?.invalidate()
            previewTimer = nil
            access = .subscribed
        } else {
            updatePreviewState()
        }
    }

    private func updatePreviewState() {
        let start = defaults.double(forKey: previewStartKey)
        guard start > 0 else {
            access = .previewAvailable
            return
        }

        let remaining = Self.remainingPreviewSeconds(
            startedAt: start,
            now: Date().timeIntervalSince1970
        )
        if remaining > 0 {
            access = .preview(secondsRemaining: remaining)
            startPreviewTimerIfNeeded()
        } else {
            previewTimer?.invalidate()
            previewTimer = nil
            access = .locked
        }
    }

    private func startPreviewTimerIfNeeded() {
        guard previewTimer == nil else { return }
        previewTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updatePreviewState()
            }
        }
    }
}
