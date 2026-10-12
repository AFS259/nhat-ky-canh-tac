import SwiftUI

@main
struct NhatKyCanhTacAFSApp: App {
    @StateObject private var appState = AppState()

    init() {
        AppTheme.configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(.light)
        }
    }
}
