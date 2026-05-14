import SwiftUI

@main
struct PathriftApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentRootView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
        }
    }
}

struct ContentRootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            switch appState.currentScreen {
            case .home:
                HomeScreen()
            case .game:
                GameView(restoreFromSave: appState.shouldRestoreSave)
            case .runEnd:
                RunEndScreen()
            case .howToPlay:
                HowToPlayScreen()
            case .settings:
                SettingsScreen()
            case .store:
                StoreScreen()
            case .arsenal:
                ArsenalScreen()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.currentScreen)
    }
}
