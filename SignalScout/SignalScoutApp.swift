import SwiftUI

@main
struct SignalScoutApp: App {
    @StateObject private var subscription = SubscriptionManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(subscription)
                .preferredColorScheme(.dark)
        }
    }
}
