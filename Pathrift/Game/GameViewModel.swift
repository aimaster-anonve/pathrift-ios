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
    @Published var riftShiftTriggered: Bool = false
    @Published var waveEnemyTotal: Int = 1
    @Published var waveEnemiesCleared: Int = 0
    @Published var diamonds: Int = DiamondStore.shared.balance
    @Published var speedMultiplier: Double = 1.0
    @Published var showPremiumPrompt: Bool = false
    @Published var showRevivePrompt: Bool = false
    @Published var reviveCountdown: Int = 5

    private var reviveTimer: Timer?

    var waveProgress: Double {
        guard waveEnemyTotal > 0 else { return 0 }
        return min(1.0, Double(waveEnemiesCleared) / Double(waveEnemyTotal))
    }

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
                GameSaveStore.shared.clear()
            }
        }
        scene.onWaveComplete = { [weak self] wave in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isWaveActive = false
                self.waveCompleteMessage = "Wave \(wave) cleared!"
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.waveCompleteMessage = nil
                }
                // Save game state after each wave
                let towers = self.scene.activeTowers.map {
                    SavedTower(slotId: $0.slotId, type: $0.type.rawValue, level: $0.level, totalInvested: $0.totalInvested)
                }
                GameSaveStore.shared.save(
                    wave: wave,
                    lives: self.lives,
                    gold: self.gold,
                    kills: self.enemyKills,
                    layoutIndex: self.scene.currentLayoutIndex,
                    towers: towers
                )
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
                        damage: tower.scaledDamage(),
                        attackSpeed: tower.effectiveAttackInterval(),
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
        scene.onWaveProgress = { [weak self] cleared, total in
            DispatchQueue.main.async {
                self?.waveEnemiesCleared = cleared
                self?.waveEnemyTotal = max(1, total)
            }
        }
        scene.onRiftShift = { [weak self] in
            DispatchQueue.main.async {
                self?.riftShiftTriggered = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self?.riftShiftTriggered = false
                }
            }
        }
        scene.onDiamondsChanged = { [weak self] balance in
            DispatchQueue.main.async { self?.diamonds = balance }
        }
        scene.onReviveAvailable = { [weak self] in
            DispatchQueue.main.async {
                self?.showRevivePrompt = true
                self?.startReviveCountdown()
            }
        }
    }

    private func startReviveCountdown() {
        reviveCountdown = 5
        reviveTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            self.reviveCountdown -= 1
            if self.reviveCountdown <= 0 {
                timer.invalidate()
                self.showRevivePrompt = false
                self.scene.declineRevive()
            }
        }
    }

    func acceptRevive() {
        reviveTimer?.invalidate()
        showRevivePrompt = false
        scene.acceptRevive()
    }

    func declineRevive() {
        reviveTimer?.invalidate()
        showRevivePrompt = false
        scene.declineRevive()
    }

    func toggleSpeed() {
        guard PremiumStore.shared.isPremium else {
            showPremiumPrompt = true
            return
        }
        let newSpeed = speedMultiplier == 1.0 ? 2.0 : 1.0
        speedMultiplier = newSpeed
        scene.setSpeedMultiplier(newSpeed)
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
                damage: tower.scaledDamage(),
                attackSpeed: tower.effectiveAttackInterval(),
                range: tower.type.range,
                sellValue: Int(Double(tower.totalInvested) * EconomyConstants.TowerSellRefund.manualPercent),
                upgradeCost: Int(Double(EconomyConstants.TowerUpgrade.baseCost) * pow(EconomyConstants.TowerUpgrade.growthRate, Double(tower.level - 1))),
                totalInvested: tower.totalInvested
            )
        }
    }

    func unlockTower(_ type: TowerType) {
        if DiamondStore.shared.unlock(type) {
            diamonds = DiamondStore.shared.balance
        }
    }
}
