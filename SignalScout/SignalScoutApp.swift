import SwiftUI

@main
struct SignalScoutApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
            #if DUO_DIAGNOSTICS
                .background {
                    if #available(iOS 27.1, *) {
                        DuoHingeDiagnostics()
                            .allowsHitTesting(false)
                    }
                }
            #endif
        }
    }
}
