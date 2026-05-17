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

    // MARK: - Inter-Wave Countdown (Build 7 — DEC-029)
    @Published var interWaveSecondsRemaining: Int = 0

    // MARK: - Wave Flash Protection (Build 9 — Fix 6)
    /// True from timer=0 until wave actually starts — prevents "NEXT WAVE" flash
    @Published var isTransitioningToWave: Bool = false

    // MARK: - Drag-and-Drop Placement (Build 8 — DEC-032)
    @Published var isDraggingTower: Bool = false
    @Published var dragTowerType: TowerType? = nil
    @Published var dragPosition: CGPoint = .zero
    @Published var dragValidSlotId: Int? = nil      // kept for legacy compatibility
    @Published var isShowingTowerMenu: Bool = false
    @Published var isDragPositionValid: Bool = false
    @Published var lastValidScenePoint: CGPoint? = nil

    // MARK: - Tower Move Mechanic (Build 8 — DEC-032)
    @Published var isMovingTower: Bool = false
    @Published var movingFromSlotId: Int? = nil
    @Published var moveCost: Int = 0

    private var reviveTimer: Timer?

    var waveProgress: Double {
        guard waveEnemyTotal > 0 else { return 0 }
        return min(1.0, Double(waveEnemiesCleared) / Double(waveEnemyTotal))
    }

    // MARK: - Tower Counter (Build 7)
    var activeTowerCount: Int { scene.activeTowers.count }
    var maxTowerCount: Int { scene.activeSlotCount() }
    var canAddTower: Bool { !isWaveActive && activeTowerCount < maxTowerCount }

    var nextWaveDefinition: WaveDefinition {
        scene.waveSystem.waveDefinition(for: scene.currentWaveNumber + 1)
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

    init(restoreFromSave: Bool = false) {
        let screenSize = UIScreen.main.bounds.size
        let scene = GameScene(size: screenSize)
        scene.scaleMode = .resizeFill
        if restoreFromSave, let save = GameSaveStore.shared.load() {
            scene.queueRestore(save)
        }
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
                self.isTransitioningToWave = false  // Fix 6: wave bitti, temizle
                self.waveCompleteMessage = "Wave \(wave) cleared!"
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.waveCompleteMessage = nil
                }
                // Save game state after each wave (Build 8: position fraction format — DEC-032)
                let sceneW = self.scene.size.width
                let sceneH = self.scene.size.height
                let towers = self.scene.activeTowers.map { tower in
                    SavedTower(
                        xFrac: sceneW > 0 ? Double(tower.position.x / sceneW) : 0,
                        yFrac: sceneH > 0 ? Double(tower.position.y / sceneH) : 0,
                        type: tower.type.rawValue,
                        level: tower.level,
                        totalInvested: tower.totalInvested
                    )
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
        scene.onInterWaveTimerChanged = { [weak self] seconds in
            DispatchQueue.main.async {
                self?.interWaveSecondsRemaining = seconds
                // Fix 6: timer 0'a gelince transition flag set et — "NEXT WAVE" flash önlenir
                if seconds == 0 { self?.isTransitioningToWave = true }
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
        isTransitioningToWave = false  // Fix 6: wave başladı, transition temizle
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

    // MARK: - Drag-and-Drop Placement (Build 8 — DEC-032)

    func startDragPlacement(type: TowerType) {
        dragPosition = .zero          // reset so .onAppear places ghost at center (Fix 1)
        isDraggingTower = true
        dragTowerType = type
        selectedTowerSlotId = nil
        selectedTowerInfo = nil
        isShowingTowerMenu = false
        isDragPositionValid = false
        lastValidScenePoint = nil
    }

    /// Called from drag gesture — converts screen point to scene coords and validates.
    func updateDragFromScreen(_ screenPoint: CGPoint, sceneSize: CGSize) {
        dragPosition = screenPoint
        // SpriteKit Y is flipped relative to UIKit
        let sp = CGPoint(x: screenPoint.x, y: sceneSize.height - screenPoint.y)
        let excludeId: Int? = isMovingTower ? movingFromSlotId : nil
        let valid = scene.isValidPlacement(sp, excludingTowerId: excludeId)
        isDragPositionValid = valid
        if valid { lastValidScenePoint = sp }
    }

    /// Confirm button tapped — place or move tower at last valid scene point.
    func confirmPlacement() {
        guard let sp = lastValidScenePoint else { cancelDrag(); return }
        defer { cancelDrag() }
        if isMovingTower, let towerId = movingFromSlotId {
            let _ = scene.completeMoveTower(towerId: towerId, toPoint: sp, goldCost: moveCost)
        } else if let type = dragTowerType {
            let _ = scene.placeTowerFreeform(type: type, at: sp)
        }
    }

    func cancelDrag() {
        isDraggingTower = false
        dragTowerType = nil
        dragValidSlotId = nil
        isDragPositionValid = false
        lastValidScenePoint = nil
        isMovingTower = false
        movingFromSlotId = nil
    }

    // MARK: - Tower Move Mode (Build 9 — Fix 5: ghost starts at tower's current screen position)

    func beginMoveMode(towerId: Int, moveCost: Int) {
        isMovingTower = true
        movingFromSlotId = towerId
        self.moveCost = moveCost
        selectedTowerSlotId = nil
        selectedTowerInfo = nil
        isDraggingTower = true
        isDragPositionValid = false
        lastValidScenePoint = nil
        scene.hideRangeRing()

        // Ghost tower'ın mevcut ekran pozisyonundan başlasın (isMovingTower=true olduğu için .onAppear center'a atlamaz)
        if let screenPos = scene.towerScreenPosition(for: towerId) {
            dragPosition = screenPos
            let scenePoint = CGPoint(x: screenPos.x, y: scene.size.height - screenPos.y)
            let valid = scene.isValidPlacement(scenePoint, excludingTowerId: towerId)
            isDragPositionValid = valid
            if valid { lastValidScenePoint = scenePoint }
        }
    }
}
