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
                GameView()
            case .runEnd:
                RunEndScreen()
            case .howToPlay:
                HowToPlayScreen()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.currentScreen)
    }
}
