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

    private(set) var lives: Int = EconomyConstants.startingLives
    private(set) var currentWaveNumber: Int = 0
    private(set) var enemyKills: Int = 0
    private(set) var isWaveActive: Bool = false
    private(set) var isGameOver: Bool = false

    private var lastUpdateTime: TimeInterval = 0

    // MARK: - Callbacks (bridge to SwiftUI)
    var onGoldChanged: ((Int) -> Void)?
    var onLivesChanged: ((Int) -> Void)?
    var onWaveChanged: ((Int) -> Void)?
    var onKillsChanged: ((Int) -> Void)?
    var onGameOver: ((RunResult) -> Void)?
    var onWaveComplete: ((Int) -> Void)?

    // MARK: - Setup

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 1)
        setupLayers()
        setupGround()
        setupPath()
        setupTowerSlots()
        goldManager.setChangeHandler { [weak self] gold in
            self?.onGoldChanged?(gold)
        }
        onGoldChanged?(goldManager.gold)
        onLivesChanged?(lives)
        onWaveChanged?(currentWaveNumber)
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
        let tileSize = gridSystem.tileSize
        let cols = gridSystem.columns
        let rows = gridSystem.rows

        for col in 0..<cols {
            for row in 0..<rows {
                let tile = SKShapeNode(rectOf: CGSize(width: tileSize - 1, height: tileSize - 1), cornerRadius: 2)
                let dark = (col + row) % 2 == 0
                tile.fillColor = dark
                    ? SKColor(red: 0.07, green: 0.07, blue: 0.10, alpha: 1)
                    : SKColor(red: 0.09, green: 0.09, blue: 0.13, alpha: 1)
                tile.strokeColor = SKColor(red: 0.15, green: 0.15, blue: 0.20, alpha: 0.5)
                tile.lineWidth = 0.5
                tile.position = CGPoint(
                    x: CGFloat(col) * tileSize + tileSize / 2,
                    y: CGFloat(row) * tileSize + tileSize / 2
                )
                groundLayer.addChild(tile)
            }
        }
    }

    private func setupPath() {
        let waypoints = PathSystem.waypoints
        guard waypoints.count >= 2 else { return }

        let pathThickness: CGFloat = 20

        for i in 1..<waypoints.count {
            let from = waypoints[i - 1]
            let to = waypoints[i]
            let dx = to.x - from.x
            let dy = to.y - from.y
            let length = sqrt(dx * dx + dy * dy)
            let angle = atan2(dy, dx)
            let midX = (from.x + to.x) / 2
            let midY = (from.y + to.y) / 2

            let segment = SKShapeNode(rectOf: CGSize(width: length, height: pathThickness), cornerRadius: 4)
            segment.fillColor = SKColor(red: 0.3, green: 0.25, blue: 0.15, alpha: 0.9)
            segment.strokeColor = SKColor(red: 0.5, green: 0.4, blue: 0.2, alpha: 0.8)
            segment.lineWidth = 1.5
            segment.position = CGPoint(x: midX, y: midY)
            segment.zRotation = angle
            pathLayer.addChild(segment)
        }

        for (idx, point) in waypoints.enumerated() {
            let dot = SKShapeNode(circleOfRadius: pathThickness / 2)
            dot.fillColor = SKColor(red: 0.3, green: 0.25, blue: 0.15, alpha: 0.9)
            dot.strokeColor = SKColor.clear
            dot.position = point
            pathLayer.addChild(dot)

            if idx == 0 {
                let startLabel = SKLabelNode(text: "START")
                startLabel.fontSize = 9
                startLabel.fontColor = SKColor.green
                startLabel.fontName = "AvenirNext-Bold"
                startLabel.position = CGPoint(x: point.x, y: point.y + 16)
                pathLayer.addChild(startLabel)
            } else if idx == waypoints.count - 1 {
                let endLabel = SKLabelNode(text: "END")
                endLabel.fontSize = 9
                endLabel.fontColor = SKColor.red
                endLabel.fontName = "AvenirNext-Bold"
                endLabel.position = CGPoint(x: point.x, y: point.y + 16)
                pathLayer.addChild(endLabel)
            }
        }
    }

    private func setupTowerSlots() {
        for slot in gridSystem.slots {
            let slotNode = SKShapeNode(rectOf: CGSize(width: 44, height: 44), cornerRadius: 6)
            slotNode.fillColor = SKColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 0.6)
            slotNode.strokeColor = SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: 0.7)
            slotNode.lineWidth = 1.5
            slotNode.position = slot.position
            slotNode.name = "slot_\(slot.id)"

            let plusLabel = SKLabelNode(text: "+")
            plusLabel.fontSize = 18
            plusLabel.fontColor = SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: 0.8)
            plusLabel.fontName = "AvenirNext-Bold"
            plusLabel.verticalAlignmentMode = .center
            plusLabel.horizontalAlignmentMode = .center
            slotNode.addChild(plusLabel)

            towerSlotLayer.addChild(slotNode)
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
                onSlotTapped?(slotId)
                return
            }
        }
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
        onWaveChanged?(currentWaveNumber)

        showWaveBanner(wave: currentWaveNumber)
    }

    private func showWaveBanner(wave: Int) {
        let banner = SKLabelNode(text: "WAVE \(wave)")
        banner.fontSize = 28
        banner.fontColor = SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: 1)
        banner.fontName = "AvenirNext-Bold"
        banner.position = CGPoint(x: size.width / 2, y: size.height / 2 + 20)
        banner.zPosition = 10
        banner.alpha = 0
        addChild(banner)

        banner.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.wait(forDuration: 1.0),
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
                onKillsChanged?(enemyKills)
            } else if enemy.hasReachedEnd {
                endReachedIndices.append(idx)
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

    func pauseGame() {
        isPaused = true
    }

    func resumeGame() {
        isPaused = false
    }
}
