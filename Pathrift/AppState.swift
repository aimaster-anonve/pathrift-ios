import Foundation
import Combine

enum Screen: Equatable {
    case home
    case game
    case runEnd
    case howToPlay
}

final class AppState: ObservableObject {
    @Published var currentScreen: Screen = .home
    @Published var lastRunResult: RunResult?

    func startGame() {
        lastRunResult = nil
        currentScreen = .game
    }

    func endRun(result: RunResult) {
        lastRunResult = result
        currentScreen = .runEnd
    }

    func goHome() {
        currentScreen = .home
    }

    func returnToMainMenu() {
        currentScreen = .home
    }

    func showHowToPlay() {
        currentScreen = .howToPlay
    }
}
