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
    @Published var selectedTowerSlotId: Int? = nil
    @Published var selectedTowerInfo: TowerInfo? = nil

    struct TowerInfo {
        let slotId: Int
        let towerType: TowerType
        let level: Int
        let damage: CGFloat
        let attackSpeed: TimeInterval
        let range: CGFloat
        let sellValue: Int
        let upgradeCost: Int
        let totalInvested: Int
    }

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
        scene.onTowerTapped = { [weak self] slotId in
            DispatchQueue.main.async {
                guard let self else { return }
                if let tower = self.scene.activeTowers.first(where: { $0.slotId == slotId }) {
                    self.selectedTowerSlotId = slotId
                    self.selectedTowerInfo = TowerInfo(
                        slotId: slotId,
                        towerType: tower.type,
                        level: tower.level,
                        damage: tower.type.damage,
                        attackSpeed: tower.type.attackSpeed,
                        range: tower.type.range,
                        sellValue: Int(Double(tower.totalInvested) * EconomyConstants.TowerSellRefund.manualPercent),
                        upgradeCost: Int(Double(EconomyConstants.TowerUpgrade.baseCost) * pow(EconomyConstants.TowerUpgrade.growthRate, Double(tower.level - 1))),
                        totalInvested: tower.totalInvested
                    )
                } else {
                    self.selectedTowerSlotId = nil
                    self.selectedTowerInfo = nil
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

    func sellSelectedTower() {
        guard let slotId = selectedTowerSlotId else { return }
        scene.sellTower(at: slotId)
        selectedTowerSlotId = nil
        selectedTowerInfo = nil
    }

    func upgradeSelectedTower() {
        guard let slotId = selectedTowerSlotId else { return }
        scene.upgradeTower(at: slotId)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self, let slotId = self.selectedTowerSlotId,
                  let tower = self.scene.activeTowers.first(where: { $0.slotId == slotId }) else { return }
            self.selectedTowerInfo = TowerInfo(
                slotId: slotId,
                towerType: tower.type,
                level: tower.level,
                damage: tower.type.damage * (1.0 + 0.25 * CGFloat(tower.level - 1)),
                attackSpeed: tower.type.attackSpeed,
                range: tower.type.range,
                sellValue: Int(Double(tower.totalInvested) * EconomyConstants.TowerSellRefund.manualPercent),
                upgradeCost: Int(Double(EconomyConstants.TowerUpgrade.baseCost) * pow(EconomyConstants.TowerUpgrade.growthRate, Double(tower.level - 1))),
                totalInvested: tower.totalInvested
            )
        }
    }
}
