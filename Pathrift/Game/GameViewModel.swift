import SwiftUI
import UIKit
import Combine

final class GameViewModel: ObservableObject {
    @Published var gold: Int = EconomyConstants.startingGold
    @Published var lives: Int = EconomyConstants.startingLives
    @Published var currentWave: Int = 0
    @Published var enemyKills: Int = 0
    @Published var isWaveActive: Bool = false
    @Published var isGameOver: Bool = false
    @Published var waveCompleteMessage: String? = nil
    @Published var runResult: RunResult? = nil

    let scene: GameScene

    init() {
        let screenSize = UIScreen.main.bounds.size
        let scene = GameScene(size: screenSize)
        scene.scaleMode = .resizeFill
        self.scene = scene
        bindScene()
    }

    private func bindScene() {
        scene.onGoldChanged = { [weak self] gold in
            DispatchQueue.main.async { self?.gold = gold }
        }
        scene.onLivesChanged = { [weak self] lives in
            DispatchQueue.main.async { self?.lives = lives }
        }
        scene.onWaveChanged = { [weak self] wave in
            DispatchQueue.main.async {
                self?.currentWave = wave
                // isWaveActive is set by startNextWave(), not here.
                // wave=0 is the initial idle state — must NOT set active.
            }
        }
        scene.onKillsChanged = { [weak self] kills in
            DispatchQueue.main.async { self?.enemyKills = kills }
        }
        scene.onGameOver = { [weak self] result in
            DispatchQueue.main.async {
                self?.isGameOver = true
                self?.runResult = result
            }
        }
        scene.onWaveComplete = { [weak self] wave in
            DispatchQueue.main.async {
                self?.isWaveActive = false
                self?.waveCompleteMessage = "Wave \(wave) cleared!"
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self?.waveCompleteMessage = nil
                }
            }
        }
    }

    func configure(appState: AppState) {
    }

    func startNextWave() {
        scene.startNextWave()
        isWaveActive = true
    }

    func placeTower(type: TowerType, at slotId: Int) {
        scene.placeTower(type: type, at: slotId)
    }
}
