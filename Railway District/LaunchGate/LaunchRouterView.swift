import SwiftUI

/// Top-level router: shows the remote web shell while the gate resolves / stays open,
/// and the native game once the gate is blocked (or no gate URL is configured).
struct LaunchRouterView: View {
    @StateObject private var launchGate = LaunchGateController()

    var body: some View {
        Group {
            switch launchGate.phase {
            case .resolving, .remoteWebShell:
                if let url = LaunchGateConfiguration.remoteGateURL {
                    LaunchWebView(gate: launchGate, startURL: url)
                } else {
                    RootView()
                        .preferredColorScheme(.dark)
                }
            case .nativeApp:
                RootView()
                    .preferredColorScheme(.dark)
            }
        }
    }
}
