import Foundation
import SpriteKit
import CoreGraphics

final class GameScene: SKScene {

    // MARK: - Layers
    private var groundLayer = SKNode()
    private var pathLayer = SKNode()
    private var towerSlotLayer = SKNode()
    private var towerLayer = SKNode()
    private var enemyLayer = SKNode()
    private var effectLayer = SKNode()

    // MARK: - Systems
    let gridSystem = GridSystem()
    let waveSystem = WaveSystem()
    let goldManager = GoldManager()

    // MARK: - State
    private(set) var activeTowers: [any Tower] = []
    private(set) var activeEnemies: [any EnemyNode] = []
    private var enemySpawnQueue: [EnemySpawnEntry] = []
    private var spawnInterval: TimeInterval = 1.0
    private var timeSinceLastSpawn: TimeInterval = 0
    private var remainingInCurrentBatch: Int = 0
    private var currentBatchIndex: Int = 0
    private var currentSpawnBatches: [EnemySpawnEntry] = []

    private var layoutBuilt = false
    private var currentLayoutIndex: Int = 0

    private(set) var lives: Int = EconomyConstants.startingLives
    private(set) var currentWaveNumber: Int = 0
    private(set) var enemyKills: Int = 0
    private(set) var isWaveActive: Bool = false
    private(set) var isGameOver: Bool = false

    private var lastUpdateTime: TimeInterval = 0

    // MARK: - Range Ring
    private var rangeRingNode: SKShapeNode?

    func showRangeRing(for tower: any Tower) {
        hideRangeRing()
        let ring = SKShapeNode(circleOfRadius: tower.type.range)
        ring.strokeColor = SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: 0.4)
        ring.fillColor = SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: 0.06)
        ring.lineWidth = 1.5
        ring.position = tower.position
        ring.zPosition = 2.5
        effectLayer.addChild(ring)
        rangeRingNode = ring
    }

    func hideRangeRing() {
        rangeRingNode?.removeFromParent()
        rangeRingNode = nil
    }

    // MARK: - Callbacks (bridge to SwiftUI)
    var onGoldChanged: ((Int) -> Void)?
    var onLivesChanged: ((Int) -> Void)?
    var onWaveChanged: ((Int) -> Void)?
    var onKillsChanged: ((Int) -> Void)?
    var onWaveProgress: ((Int, Int) -> Void)?  // (cleared, total)

    private var waveEnemyTotal: Int = 0
    private var waveEnemiesCleared: Int = 0
    var onGameOver: ((RunResult) -> Void)?
    var onWaveComplete: ((Int) -> Void)?
    var onTowerTapped: ((Int) -> Void)?
    var onRiftShift: (() -> Void)?
    var onSelectedTowerSlotId: Int? {
        didSet {
            if onSelectedTowerSlotId == nil { hideRangeRing() }
        }
    }

    // MARK: - Setup

    override func didMove(to view: SKView) {
        anchorPoint = .zero
        backgroundColor = SKColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 1)
        setupLayers()
        goldManager.setChangeHandler { [weak self] gold in self?.onGoldChanged?(gold) }
        if size.width > 1 && size.height > 1 {
            buildAndSetupGame()
        }
        onGoldChanged?(goldManager.gold)
        onLivesChanged?(lives)
        onWaveChanged?(currentWaveNumber)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard size.width > 1, size.height > 1 else { return }
        guard !layoutBuilt else { return }
        buildAndSetupGame()
    }

    private func buildAndSetupGame() {
        layoutBuilt = true
        buildDynamicLayout()
        groundLayer.removeAllChildren()
        pathLayer.removeAllChildren()
        towerSlotLayer.removeAllChildren()
        setupGround()
        setupPath()
        setupTowerSlots()
        onGoldChanged?(goldManager.gold)
        onLivesChanged?(lives)
    }

    private func buildDynamicLayout() {
        let W = size.width
        let H = size.height

        // Z-shaped path (3 horizontal lanes, 2 vertical connectors)
        // SpriteKit Y: 0=bottom, H=top
        let y1 = H * 0.20  // bottom lane
        let y2 = H * 0.50  // middle lane
        let y3 = H * 0.78  // top lane
        let xR = W * 0.74  // right vertical x
        let xL = W * 0.26  // left vertical x

        PathSystem.waypoints = [
            CGPoint(x: -10,  y: y1),
            CGPoint(x: xR,   y: y1),
            CGPoint(x: xR,   y: y2),
            CGPoint(x: xL,   y: y2),
            CGPoint(x: xL,   y: y3),
            CGPoint(x: W+10, y: y3)
        ]

        // Slot clearance: ≥85pt from horizontal paths, ≥58pt from vertical paths.
        // No two slots closer than 80pt center-to-center (slot visual = 46pt).
        let vGap: CGFloat = 85
        let hGap: CGFloat = 58
        let safeRight = min(xR + hGap, W - 30)

        gridSystem.updateSlots([
            // Above bottom lane — 3 slots
            CGPoint(x: W*0.14, y: y1+vGap),
            CGPoint(x: W*0.40, y: y1+vGap),
            CGPoint(x: W*0.64, y: y1+vGap),
            // Right of right vertical — 2 slots
            CGPoint(x: safeRight, y: y1+(y2-y1)*0.28),
            CGPoint(x: safeRight, y: y1+(y2-y1)*0.72),
            // Below middle lane — 2 slots inside the two verticals
            CGPoint(x: W*0.36, y: y2-vGap),
            CGPoint(x: W*0.62, y: y2-vGap),
            // Right of left vertical — 1 slot
            CGPoint(x: xL+hGap, y: y2+(y3-y2)*0.42),
            // Open zone right side (x>xR, y>y2 — no path)
            CGPoint(x: safeRight, y: y2+(y3-y2)*0.38),
            // Below top lane — 3 slots, leftmost anchored past xL so never on left vertical
            CGPoint(x: xL + hGap + 5,        y: y3-vGap),  // just right of left vertical
            CGPoint(x: (xL + W) * 0.5 + 10,  y: y3-vGap),  // center-right
            CGPoint(x: min(W*0.84, W-32),     y: y3-vGap),  // right side, clamped from edge
        ])
    }

    private func setupLayers() {
        let layers: [(SKNode, CGFloat)] = [
            (groundLayer, 0),
            (pathLayer, 1),
            (towerSlotLayer, 2),
            (towerLayer, 3),
            (enemyLayer, 4),
            (effectLayer, 5)
        ]
        for (layer, z) in layers {
            layer.zPosition = z
            addChild(layer)
        }
    }

    private func setupGround() {
        let gridColor1 = SKColor(red: 0.07, green: 0.07, blue: 0.10, alpha: 1)
        let gridColor2 = SKColor(red: 0.09, green: 0.09, blue: 0.13, alpha: 1)
        let cols = 12
        let rows = 20
        let tileW = size.width / CGFloat(cols)
        let tileH = size.height / CGFloat(rows)
        for col in 0..<cols {
            for row in 0..<rows {
                let tile = SKShapeNode(rectOf: CGSize(width: tileW-0.5, height: tileH-0.5), cornerRadius: 1)
                tile.fillColor = (col+row) % 2 == 0 ? gridColor1 : gridColor2
                tile.strokeColor = SKColor(red: 0.15, green: 0.15, blue: 0.20, alpha: 0.3)
                tile.lineWidth = 0.5
                tile.position = CGPoint(x: CGFloat(col)*tileW + tileW/2, y: CGFloat(row)*tileH + tileH/2)
                groundLayer.addChild(tile)
            }
        }
    }

    private func setupPath() {
        let waypoints = PathSystem.waypoints
        guard waypoints.count >= 2 else { return }
        let thickness: CGFloat = 24
        for i in 1..<waypoints.count {
            let from = waypoints[i-1]
            let to = waypoints[i]
            let dx = to.x - from.x
            let dy = to.y - from.y
            let len = sqrt(dx*dx + dy*dy)
            let seg = SKShapeNode(rectOf: CGSize(width: len, height: thickness), cornerRadius: 5)
            seg.fillColor = SKColor(red: 0.28, green: 0.22, blue: 0.12, alpha: 0.95)
            seg.strokeColor = SKColor(red: 0.5, green: 0.38, blue: 0.18, alpha: 0.7)
            seg.lineWidth = 1.5
            seg.position = CGPoint(x: (from.x+to.x)/2, y: (from.y+to.y)/2)
            seg.zRotation = atan2(dy, dx)
            pathLayer.addChild(seg)
        }
        // Joints at corners
        for point in waypoints {
            let dot = SKShapeNode(circleOfRadius: thickness/2)
            dot.fillColor = SKColor(red: 0.28, green: 0.22, blue: 0.12, alpha: 0.95)
            dot.strokeColor = SKColor.clear
            dot.position = point
            pathLayer.addChild(dot)
        }
        // Start indicator — animated arrow at entry
        if let first = PathSystem.waypoints.first {
            // Arrow pointing right
            let arrowBg = SKShapeNode(circleOfRadius: 14)
            arrowBg.fillColor = SKColor(red: 0.0, green: 0.6, blue: 0.2, alpha: 0.9)
            arrowBg.strokeColor = SKColor(red: 0.0, green: 1.0, blue: 0.4, alpha: 0.8)
            arrowBg.lineWidth = 2
            arrowBg.position = CGPoint(x: first.x + 20, y: first.y)
            // Pulse animation
            let pulse = SKAction.repeatForever(SKAction.sequence([
                SKAction.scale(to: 1.15, duration: 0.6),
                SKAction.scale(to: 0.9, duration: 0.6)
            ]))
            arrowBg.run(pulse)
            pathLayer.addChild(arrowBg)

            let arrowLabel = SKLabelNode(text: "▶")
            arrowLabel.fontSize = 12
            arrowLabel.fontColor = .white
            arrowLabel.verticalAlignmentMode = .center
            arrowLabel.horizontalAlignmentMode = .center
            arrowBg.addChild(arrowLabel)

            let startText = SKLabelNode(text: "START")
            startText.fontSize = 8
            startText.fontName = "AvenirNext-Bold"
            startText.fontColor = SKColor(red: 0.0, green: 1.0, blue: 0.4, alpha: 0.9)
            startText.horizontalAlignmentMode = .center
            startText.position = CGPoint(x: first.x + 20, y: first.y + 24)
            pathLayer.addChild(startText)
        }

        // End indicator
        if let last = PathSystem.waypoints.last {
            let exitBg = SKShapeNode(circleOfRadius: 14)
            exitBg.fillColor = SKColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 0.9)
            exitBg.strokeColor = SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 0.8)
            exitBg.lineWidth = 2
            exitBg.position = CGPoint(x: last.x - 20, y: last.y)
            pathLayer.addChild(exitBg)

            let exitArrow = SKLabelNode(text: "✕")
            exitArrow.fontSize = 11
            exitArrow.fontColor = .white
            exitArrow.verticalAlignmentMode = .center
            exitArrow.horizontalAlignmentMode = .center
            exitBg.addChild(exitArrow)

            let exitText = SKLabelNode(text: "EXIT")
            exitText.fontSize = 8
            exitText.fontName = "AvenirNext-Bold"
            exitText.fontColor = SKColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 0.9)
            exitText.horizontalAlignmentMode = .center
            exitText.position = CGPoint(x: last.x - 20, y: last.y + 24)
            pathLayer.addChild(exitText)
        }
    }

    private func setupTowerSlots() {
        for slot in gridSystem.slots {
            let container = SKNode()
            container.position = slot.position
            container.name = "slot_\(slot.id)"

            // Background with glow
            let bg = SKShapeNode(rectOf: CGSize(width: 46, height: 46), cornerRadius: 8)
            bg.fillColor = SKColor(red: 0.05, green: 0.15, blue: 0.25, alpha: 0.85)
            bg.strokeColor = SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: 0.6)
            bg.lineWidth = 1.5
            bg.name = "slot_\(slot.id)"
            container.addChild(bg)

            // Inner cross
            let vLine = SKShapeNode(rectOf: CGSize(width: 2, height: 18), cornerRadius: 1)
            vLine.fillColor = SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: 0.7)
            vLine.strokeColor = .clear
            container.addChild(vLine)

            let hLine = SKShapeNode(rectOf: CGSize(width: 18, height: 2), cornerRadius: 1)
            hLine.fillColor = SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: 0.7)
            hLine.strokeColor = .clear
            container.addChild(hLine)

            // Subtle breathing animation
            let breathe = SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.6, duration: 1.5),
                SKAction.fadeAlpha(to: 1.0, duration: 1.5)
            ]))
            bg.run(breathe)

            towerSlotLayer.addChild(container)
        }
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        handleTap(at: location)
    }

    private func handleTap(at location: CGPoint) {
        let nodes = self.nodes(at: location)
        for node in nodes {
            if let name = node.name, name.hasPrefix("slot_"),
               let idStr = name.components(separatedBy: "_").last,
               let slotId = Int(idStr) {
                if let slot = gridSystem.slot(at: slotId) {
                    if slot.state.isOccupied {
                        if let tower = activeTowers.first(where: { $0.slotId == slotId }) {
                            showRangeRing(for: tower)
                        }
                        onTowerTapped?(slotId)
                    } else {
                        hideRangeRing()
                        onSlotTapped?(slotId)
                    }
                }
                return
            }
        }
        hideRangeRing()
        onSelectedTowerSlotId = nil
    }

    var onSlotTapped: ((Int) -> Void)?

    // MARK: - Tower Placement

    func placeTower(type: TowerType, at slotId: Int) {
        guard let slot = gridSystem.slot(at: slotId),
              case .empty = slot.state,
              goldManager.spend(type.cost) else { return }

        gridSystem.placeTower(type: type, at: slotId)

        let tower: any Tower
        switch type {
        case .bolt:
            tower = BoltTower(position: slot.position, slotId: slotId)
        case .blast:
            let blastTower = BlastTower(position: slot.position, slotId: slotId)
            blastTower.blastDamageCallback = { [weak self] center, radius, damage in
                guard let self = self else { return }
                for enemy in self.activeEnemies {
                    guard enemy.isAlive else { continue }
                    let dx = enemy.node.position.x - center.x
                    let dy = enemy.node.position.y - center.y
                    if sqrt(dx * dx + dy * dy) <= radius {
                        enemy.applyDamage(damage)
                    }
                }
            }
            tower = blastTower
        case .frost:
            tower = FrostTower(position: slot.position, slotId: slotId)
        }

        activeTowers.append(tower)
        towerLayer.addChild(tower.node)
        addLevelBadge(to: tower)

        // Hidden slot node is NOT hit-testable — add transparent tap detector instead.
        let tapDetector = SKShapeNode(circleOfRadius: 28)
        tapDetector.fillColor = SKColor.clear
        tapDetector.strokeColor = SKColor.clear
        tapDetector.name = "slot_\(slotId)"
        tapDetector.position = slot.position
        tapDetector.zPosition = 6
        towerLayer.addChild(tapDetector)

        if let slotNode = towerSlotLayer.childNode(withName: "slot_\(slotId)") {
            slotNode.isHidden = true
        }
    }

    // MARK: - Wave Management

    func startNextWave() {
        guard !isGameOver else { return }
        let waveDef = waveSystem.nextWave()
        currentWaveNumber = waveDef.waveNumber
        spawnInterval = waveDef.spawnInterval
        currentSpawnBatches = waveDef.spawns
        currentBatchIndex = 0
        remainingInCurrentBatch = currentSpawnBatches.first?.count ?? 0
        timeSinceLastSpawn = spawnInterval
        isWaveActive = true
        waveEnemyTotal = waveDef.totalEnemyCount
        waveEnemiesCleared = 0
        onWaveChanged?(currentWaveNumber)
        onWaveProgress?(0, waveEnemyTotal)

        showWaveBanner(wave: currentWaveNumber)
    }

    private func showWaveBanner(wave: Int) {
        let isBoss = waveSystem.isBossWave(wave)
        let text = isBoss ? "⚠️ BOSS WAVE \(wave) ⚠️" : "WAVE \(wave)"
        let fontSize: CGFloat = isBoss ? 24 : 28
        let color = isBoss
            ? SKColor(red: 1.0, green: 0.3, blue: 0.8, alpha: 1)
            : SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: 1)

        let banner = SKLabelNode(text: text)
        banner.fontSize = fontSize
        banner.fontColor = color
        banner.fontName = "AvenirNext-Bold"
        banner.position = CGPoint(x: size.width / 2, y: size.height * 0.55)
        banner.zPosition = 10
        banner.alpha = 0
        addChild(banner)

        if isBoss {
            let shake = SKAction.sequence([
                SKAction.moveBy(x: 8, y: 0, duration: 0.05),
                SKAction.moveBy(x: -16, y: 0, duration: 0.05),
                SKAction.moveBy(x: 16, y: 0, duration: 0.05),
                SKAction.moveBy(x: -8, y: 0, duration: 0.05),
            ])
            run(SKAction.repeat(shake, count: 3))
        }

        banner.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.wait(forDuration: isBoss ? 1.5 : 1.0),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Enemy Spawning

    private func spawnNextEnemy() {
        guard currentBatchIndex < currentSpawnBatches.count else {
            isWaveActive = activeEnemies.contains { $0.isAlive }
            return
        }

        let batch = currentSpawnBatches[currentBatchIndex]
        if remainingInCurrentBatch <= 0 {
            currentBatchIndex += 1
            if currentBatchIndex < currentSpawnBatches.count {
                remainingInCurrentBatch = currentSpawnBatches[currentBatchIndex].count
            }
            return
        }

        let hpMult = waveSystem.hpScaleMultiplier(for: currentWaveNumber)
        let enemy: any EnemyNode

        switch batch.type {
        case .runner:
            enemy = RunnerEnemy(hpMultiplier: hpMult)
        case .tank:
            enemy = TankEnemy(hpMultiplier: hpMult)
        case .boss:
            enemy = BossEnemy(waveNumber: currentWaveNumber)
        }

        activeEnemies.append(enemy)
        enemyLayer.addChild(enemy.node)
        remainingInCurrentBatch -= 1
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        let deltaTime: TimeInterval
        if lastUpdateTime == 0 {
            deltaTime = 0
        } else {
            deltaTime = min(currentTime - lastUpdateTime, 0.05)
        }
        lastUpdateTime = currentTime

        guard !isGameOver else { return }

        if isWaveActive {
            timeSinceLastSpawn += deltaTime
            if timeSinceLastSpawn >= spawnInterval {
                timeSinceLastSpawn = 0
                spawnNextEnemy()
            }
        }

        updateEnemies(deltaTime: deltaTime, currentTime: currentTime)
        updateTowers(currentTime: currentTime)
        checkWaveCompletion()
    }

    private func updateEnemies(deltaTime: TimeInterval, currentTime: TimeInterval) {
        var deadIndices: [Int] = []
        var endReachedIndices: [Int] = []

        for (idx, enemy) in activeEnemies.enumerated() {
            enemy.updateSlowEffect(currentTime: currentTime)
            enemy.updateMovement(deltaTime: deltaTime)

            if enemy.isDead {
                deadIndices.append(idx)
                goldManager.earn(enemy.goldReward)
                enemyKills += 1
                waveEnemiesCleared += 1
                onKillsChanged?(enemyKills)
                onWaveProgress?(waveEnemiesCleared, waveEnemyTotal)
            } else if enemy.hasReachedEnd {
                endReachedIndices.append(idx)
                waveEnemiesCleared += 1
                onWaveProgress?(waveEnemiesCleared, waveEnemyTotal)
                loseLife()
            }
        }

        let toRemove = Set(deadIndices + endReachedIndices)
        activeEnemies = activeEnemies.enumerated()
            .filter { !toRemove.contains($0.offset) }
            .map { $0.element }
    }

    private func updateTowers(currentTime: TimeInterval) {
        for tower in activeTowers {
            guard tower.canFire(at: currentTime) else { continue }

            let inRange = activeEnemies.filter {
                $0.isAlive && isEnemy($0, inRangeOf: tower)
            }

            guard let target = inRange.max(by: { $0.pathProgress < $1.pathProgress }) else {
                continue
            }

            tower.fire(at: target, scene: self, currentTime: currentTime)
        }
    }

    private func isEnemy(_ enemy: any EnemyNode, inRangeOf tower: any Tower) -> Bool {
        let dx = enemy.node.position.x - tower.position.x
        let dy = enemy.node.position.y - tower.position.y
        return sqrt(dx * dx + dy * dy) <= tower.type.range
    }

    private func checkWaveCompletion() {
        guard isWaveActive else { return }
        let noMoreSpawns = currentBatchIndex >= currentSpawnBatches.count && remainingInCurrentBatch <= 0
        let noActiveEnemies = activeEnemies.filter { $0.isAlive }.isEmpty

        if noMoreSpawns && noActiveEnemies {
            isWaveActive = false
            goldManager.awardWaveReward(wave: currentWaveNumber)
            onWaveComplete?(currentWaveNumber)
            riftShiftCheck(completedWave: currentWaveNumber)
        }
    }

    private func loseLife() {
        lives = max(0, lives - 1)
        onLivesChanged?(lives)

        let shake = SKAction.sequence([
            SKAction.moveBy(x: 8, y: 0, duration: 0.05),
            SKAction.moveBy(x: -16, y: 0, duration: 0.05),
            SKAction.moveBy(x: 16, y: 0, duration: 0.05),
            SKAction.moveBy(x: -8, y: 0, duration: 0.05)
        ])
        run(shake)

        if lives <= 0 {
            triggerGameOver()
        }
    }

    private func triggerGameOver() {
        isGameOver = true
        isWaveActive = false

        let score = ScoreCalculator.calculate(wavesReached: currentWaveNumber, enemyKills: enemyKills)
        let result = RunResult(
            score: score,
            wavesReached: currentWaveNumber,
            enemyKills: enemyKills,
            isVictory: false
        )

        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor = SKColor.black.withAlphaComponent(0.6)
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.zPosition = 20
        addChild(overlay)

        let gameOverLabel = SKLabelNode(text: "GAME OVER")
        gameOverLabel.fontSize = 42
        gameOverLabel.fontColor = SKColor(red: 1.0, green: 0.17, blue: 0.33, alpha: 1)
        gameOverLabel.fontName = "AvenirNext-Bold"
        gameOverLabel.verticalAlignmentMode = .center
        gameOverLabel.horizontalAlignmentMode = .center
        gameOverLabel.position = .zero
        overlay.addChild(gameOverLabel)

        run(SKAction.wait(forDuration: 2.0)) { [weak self] in
            self?.onGameOver?(result)
        }
    }

    // MARK: - Tower Management

    func sellTower(at slotId: Int) {
        guard let towerIdx = activeTowers.firstIndex(where: { $0.slotId == slotId }) else { return }
        let tower = activeTowers[towerIdx]
        let refund = Int(Double(tower.totalInvested) * EconomyConstants.TowerSellRefund.manualPercent)
        goldManager.earn(refund)
        tower.node.removeFromParent()
        // Also remove the tap detector we added on placement
        towerLayer.childNode(withName: "slot_\(slotId)")?.removeFromParent()
        activeTowers.remove(at: towerIdx)
        gridSystem.removeTower(at: slotId)
        hideRangeRing()
        if let slotNode = towerSlotLayer.childNode(withName: "slot_\(slotId)") {
            slotNode.isHidden = false
        }
    }

    func upgradeTower(at slotId: Int) {
        guard let tower = activeTowers.first(where: { $0.slotId == slotId }) else { return }
        let upgradeCost = Int(Double(EconomyConstants.TowerUpgrade.baseCost) *
                             pow(EconomyConstants.TowerUpgrade.growthRate, Double(tower.level - 1)))
        guard goldManager.spend(upgradeCost) else { return }
        tower.level += 1
        tower.totalInvested += upgradeCost
        updateLevelBadge(for: tower)
        let flash = SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.15)
        ])
        tower.node.run(flash)
    }

    // MARK: - Level Badge

    private func addLevelBadge(to tower: any Tower) {
        let badge = SKShapeNode(circleOfRadius: 7)
        badge.fillColor = SKColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 0.95)
        badge.strokeColor = SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: 0.9)
        badge.lineWidth = 1
        badge.name = "levelBadge"
        badge.position = CGPoint(x: 14, y: -14)
        badge.zPosition = 2
        let lbl = SKLabelNode(text: "1")
        lbl.fontSize = 8
        lbl.fontName = "AvenirNext-Bold"
        lbl.fontColor = SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: 1)
        lbl.verticalAlignmentMode = .center
        lbl.horizontalAlignmentMode = .center
        badge.addChild(lbl)
        tower.node.addChild(badge)
    }

    private func updateLevelBadge(for tower: any Tower) {
        guard let badge = tower.node.childNode(withName: "levelBadge") as? SKShapeNode,
              let lbl = badge.children.first as? SKLabelNode else { return }
        lbl.text = "\(tower.level)"
        // Colour escalates: blue → purple → orange
        let (stroke, text): (SKColor, SKColor)
        switch tower.level {
        case ..<3:  (stroke, text) = (SKColor(red:0.0,green:0.78,blue:1.0,alpha:1),   SKColor(red:0.0,green:0.78,blue:1.0,alpha:1))
        case 3..<6: (stroke, text) = (SKColor(red:0.55,green:0.31,blue:1.0,alpha:1),  SKColor(red:0.55,green:0.31,blue:1.0,alpha:1))
        default:    (stroke, text) = (SKColor(red:1.0,green:0.42,blue:0.0,alpha:1),   SKColor(red:1.0,green:0.42,blue:0.0,alpha:1))
        }
        badge.strokeColor = stroke
        lbl.fontColor = text
        badge.run(SKAction.sequence([SKAction.scale(to:1.4,duration:0.1), SKAction.scale(to:1.0,duration:0.1)]))
    }

    func pauseGame() {
        isPaused = true
    }

    func resumeGame() {
        isPaused = false
    }

    // MARK: - Rift Shift

    private func riftShiftCheck(completedWave: Int) {
        guard completedWave % 5 == 0 else { return }
        triggerRiftShift()
    }

    private func triggerRiftShift() {
        showRiftShiftBanner()

        run(SKAction.wait(forDuration: 1.5)) { [weak self] in
            self?.performRiftShift()
            self?.onRiftShift?()
        }
    }

    private func showRiftShiftBanner() {
        let overlay = SKShapeNode(rectOf: CGSize(width: size.width, height: 60))
        overlay.fillColor = SKColor(red: 0.55, green: 0.31, blue: 1.0, alpha: 0.85)
        overlay.strokeColor = SKColor(red: 0.7, green: 0.5, blue: 1.0, alpha: 1)
        overlay.lineWidth = 2
        overlay.position = CGPoint(x: size.width / 2, y: size.height * 0.55)
        overlay.zPosition = 15
        overlay.alpha = 0
        addChild(overlay)

        let label = SKLabelNode(text: "⚡ RIFT SHIFT ⚡")
        label.fontSize = 22
        label.fontName = "AvenirNext-Black"
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        overlay.addChild(label)

        overlay.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.2),
            SKAction.wait(forDuration: 1.0),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))

        // Screen flash effect
        let flash = SKShapeNode(rectOf: size)
        flash.fillColor = SKColor(red: 0.55, green: 0.31, blue: 1.0, alpha: 0.15)
        flash.strokeColor = SKColor.clear
        flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flash.zPosition = 14
        addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.1),
            SKAction.fadeOut(withDuration: 0.4),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Map Layouts (5 completely different configurations)

    // MARK: - Layout System (12 layouts — guaranteed slot/path separation)

    // Derives slot positions algorithmically so they NEVER land on the path.
    // Works for both forward (y1<y2<y3) and reverse (y1>y2>y3) Z-shapes.
    private func computeSlots(y1: CGFloat, y2: CGFloat, y3: CGFloat,
                               xL: CGFloat, xR: CGFloat) -> [CGPoint] {
        let W = size.width, H = size.height
        let vGap: CGFloat = 92   // vertical clearance from horizontal segment
        let hGap: CGFloat = 68   // horizontal clearance from vertical segment
        let edge: CGFloat = 30   // minimum distance from screen edge
        let minSep: CGFloat = 56 // minimum slot-to-slot distance

        let fwd = y1 < y2
        // Interior-facing offsets — always place slots on the "inside" of the Z
        let seg1Side = y1 + (fwd ?  vGap : -vGap)
        let seg3Side = y2 + (fwd ? -vGap :  vGap)
        let seg5Side = y3 + (fwd ? -vGap :  vGap)
        let srx = min(xR + hGap, W - edge)   // right of xR, clamped to screen

        let cands: [CGPoint] = [
            // Adjacent to first horizontal (seg1)
            CGPoint(x: W*0.14,                         y: seg1Side),
            CGPoint(x: W*0.40,                         y: seg1Side),
            CGPoint(x: min(W*0.64, xR-hGap-8),        y: seg1Side),
            // Right of right vertical (seg2)
            CGPoint(x: srx, y: y1 + (y2-y1)*0.27),
            CGPoint(x: srx, y: y1 + (y2-y1)*0.73),
            // Adjacent to middle horizontal (seg3) — between the two verticals
            CGPoint(x: max(W*0.36, xL+hGap+12),       y: seg3Side),
            CGPoint(x: min(W*0.62, xR-hGap-12),       y: seg3Side),
            // Right of left vertical (seg4)
            CGPoint(x: xL + hGap,  y: y2 + (y3-y2)*0.33),
            CGPoint(x: xL + hGap,  y: y2 + (y3-y2)*0.68),
            // Open right zone (x > xR between y2 and y3 — no path segment here)
            CGPoint(x: srx,         y: y2 + (y3-y2)*0.46),
            // Adjacent to last horizontal (seg5)
            CGPoint(x: max(xL+hGap+6, W*0.20),        y: seg5Side),
            CGPoint(x: (xL+W)*0.5 + 8,                y: seg5Side),
            CGPoint(x: min(W*0.80, W-edge),            y: seg5Side),
        ]

        var result: [CGPoint] = []
        for c in cands {
            guard c.x >= edge, c.x <= W-edge, c.y >= edge, c.y <= H-edge else { continue }
            let tooClose = result.contains { e in hypot(c.x-e.x, c.y-e.y) < minSep }
            if !tooClose { result.append(c) }
        }
        return Array(result.prefix(12))
    }

    // 12 layout parameter sets — (y1%, y2%, y3%, xL%, xR%) all as fractions of H/W.
    // Minimum vertical lane gap: 0.22H (~187pt). Minimum horizontal width: 0.36W (~141pt).
    private let layoutParams: [(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)] = [
        (0.20, 0.50, 0.78, 0.26, 0.74),   // 0: standard forward Z
        (0.78, 0.50, 0.22, 0.28, 0.72),   // 1: reverse Z
        (0.12, 0.50, 0.88, 0.18, 0.82),   // 2: wide Z
        (0.28, 0.50, 0.72, 0.30, 0.70),   // 3: tight centre
        (0.20, 0.53, 0.84, 0.15, 0.60),   // 4: left-heavy
        (0.16, 0.50, 0.84, 0.40, 0.85),   // 5: right-heavy
        (0.15, 0.40, 0.78, 0.25, 0.75),   // 6: upper double
        (0.22, 0.60, 0.85, 0.26, 0.74),   // 7: lower double
        (0.82, 0.48, 0.16, 0.22, 0.78),   // 8: wide reverse
        (0.20, 0.44, 0.80, 0.35, 0.65),   // 9: compressed mid
        (0.18, 0.58, 0.82, 0.24, 0.76),   // 10: lower compressed
        (0.75, 0.44, 0.17, 0.32, 0.68),   // 11: narrow reverse
    ]

    private func layoutConfig(index: Int) -> (waypoints: [CGPoint], slots: [CGPoint]) {
        let W = size.width, H = size.height
        let p = layoutParams[index % layoutParams.count]
        let y1 = H*p.0, y2 = H*p.1, y3 = H*p.2, xL = W*p.3, xR = W*p.4
        let waypoints: [CGPoint] = [
            CGPoint(x: -10,   y: y1),
            CGPoint(x: xR,    y: y1),
            CGPoint(x: xR,    y: y2),
            CGPoint(x: xL,    y: y2),
            CGPoint(x: xL,    y: y3),
            CGPoint(x: W+10,  y: y3),
        ]
        return (waypoints, computeSlots(y1: y1, y2: y2, y3: y3, xL: xL, xR: xR))
    }

    private func performRiftShift() {
        // Pick a completely different layout — never repeat the same one
        var newIndex = Int.random(in: 0..<layoutParams.count)
        if newIndex == currentLayoutIndex {
            newIndex = (newIndex + 1 + Int.random(in: 1..<layoutParams.count)) % layoutParams.count
        }
        currentLayoutIndex = newIndex
        let layout = layoutConfig(index: newIndex)

        // Update path and slot data
        PathSystem.waypoints = layout.waypoints
        let towerSnapshot = activeTowers.map { (slotId: $0.slotId, type: $0.type, tower: $0) }
        gridSystem.updateSlots(layout.slots)

        // Redraw map
        pathLayer.removeAllChildren()
        towerSlotLayer.removeAllChildren()
        setupPath()
        setupTowerSlots()

        // Decide which towers survive the Rift
        // Each tower independently: 60% survive, 40% destroyed. Always keep ≥1.
        var survivors = towerSnapshot.filter { _ in Int.random(in: 0..<5) < 3 }
        if survivors.isEmpty, let first = towerSnapshot.first { survivors = [first] }
        let destroyedTowers = towerSnapshot.filter { snap in !survivors.contains(where: { $0.slotId == snap.slotId }) }

        // Destroy non-survivors
        for snap in destroyedTowers {
            spawnDestroyedTowerEffect(at: snap.tower.position)
            snap.tower.node.removeFromParent()
            towerLayer.childNode(withName: "slot_\(snap.slotId)")?.removeFromParent()
            gridSystem.removeTower(at: snap.slotId)
            let refund = Int(Double(snap.tower.totalInvested) * EconomyConstants.TowerSellRefund.riftForcedPercent)
            goldManager.earn(refund)
        }
        activeTowers.removeAll { snap in destroyedTowers.contains(where: { $0.slotId == snap.slotId }) }

        // Assign survivors to randomly-shuffled new slots
        let availableSlotIds = Array(0..<gridSystem.slots.count).shuffled()
        for (i, snap) in survivors.enumerated() {
            let targetSlotId = i < availableSlotIds.count ? availableSlotIds[i] : snap.slotId
            guard let newSlot = gridSystem.slot(at: targetSlotId) else { continue }
            let newPos = newSlot.position

            // Update tower's logical slot and position
            snap.tower.position = newPos
            // Reassign slotId via gridSystem
            gridSystem.placeTower(type: snap.type, at: targetSlotId)

            // Animate move
            snap.tower.node.run(SKAction.sequence([
                SKAction.group([
                    SKAction.move(to: newPos, duration: 0.5),
                    SKAction.sequence([SKAction.scale(to: 1.25, duration: 0.15), SKAction.scale(to: 1.0, duration: 0.15)])
                ])
            ]))

            // Move or recreate tap detector
            towerLayer.childNode(withName: "slot_\(snap.slotId)")?.removeFromParent()
            let tapDet = SKShapeNode(circleOfRadius: 28)
            tapDet.fillColor = SKColor.clear; tapDet.strokeColor = SKColor.clear
            tapDet.name = "slot_\(targetSlotId)"; tapDet.position = newPos; tapDet.zPosition = 6
            towerLayer.addChild(tapDet)

            // Hide new slot indicator
            towerSlotLayer.childNode(withName: "slot_\(targetSlotId)")?.isHidden = true
        }

        // Update tower.slotId to match new assignment so tap lookup works correctly
        for (i, snap) in survivors.enumerated() {
            let targetSlotId = i < availableSlotIds.count ? availableSlotIds[i] : snap.slotId
            snap.tower.slotId = targetSlotId   // now var — tap detection stays in sync
        }

        hideRangeRing()
    }

    private func spawnDestroyedTowerEffect(at pos: CGPoint) {
        for _ in 0..<8 {
            let p = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
            p.fillColor = SKColor(red: 0.55, green: 0.31, blue: 1.0, alpha: 1)
            p.strokeColor = SKColor.clear
            p.position = pos; p.zPosition = 8
            effectLayer.addChild(p)
            let angle = CGFloat.random(in: 0 ..< 2 * .pi)
            let dist  = CGFloat.random(in: 25...65)
            p.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: cos(angle)*dist, y: sin(angle)*dist, duration: 0.4),
                    SKAction.fadeOut(withDuration: 0.4)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }
}
