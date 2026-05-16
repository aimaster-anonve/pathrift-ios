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
    private(set) var currentLayoutIndex: Int = 0

    /// Slots available increases with wave — more room to defend as game gets harder.
    private func activeSlotCount() -> Int {
        switch currentWaveNumber {
        case ..<5:    return 5
        case 5..<10:  return 7
        case 10..<20: return 9
        default:      return 11
        }
    }

    private(set) var lives: Int = EconomyConstants.startingLives
    private(set) var currentWaveNumber: Int = 0
    private(set) var enemyKills: Int = 0
    private(set) var isWaveActive: Bool = false
    private(set) var isGameOver: Bool = false

    var speedMultiplier: Double = 1.0
    private var hasUsedRevive: Bool = false

    // MARK: - HUD Insets (set by GameView to keep path/slots out from under the HUD)
    var hudTopInset: CGFloat = 48
    var hudBottomInset: CGFloat = 46

    /// Effective game area (excluding HUD, in SpriteKit coordinates where y=0 is bottom)
    private var contentMinY: CGFloat { hudBottomInset }
    private var contentMaxY: CGFloat { size.height - hudTopInset }
    private var contentHeight: CGFloat { max(1, contentMaxY - contentMinY) }
    private var contentWidth: CGFloat { max(1, size.width) }  // full width, safe area handles sides

    var onReviveAvailable: (() -> Void)?
    var onSpeedChanged: ((Double) -> Void)?

    private var lastUpdateTime: TimeInterval = 0

    // MARK: - Boss Ability State
    /// Set to true while a Rift Pulse debuff is active — towers fire at 40% rate
    private(set) var towerAttackSpeedDebuffActive: Bool = false

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
    var onDiamondsChanged: ((Int) -> Void)?

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

    // Set before presentation to restore a saved game instead of starting fresh
    private var pendingRestore: GameSaveState? = nil

    func queueRestore(_ save: GameSaveState) {
        pendingRestore = save
    }

    private func buildAndSetupGame() {
        layoutBuilt = true
        hasUsedRevive = false
        speedMultiplier = 1.0

        if let save = pendingRestore {
            currentLayoutIndex = save.layoutIndex
            applyLayout(index: currentLayoutIndex)
        } else {
            buildDynamicLayout()
        }

        groundLayer.removeAllChildren()
        pathLayer.removeAllChildren()
        towerSlotLayer.removeAllChildren()
        setupGround()
        setupPath()
        setupTowerSlots()

        if let save = pendingRestore {
            pendingRestore = nil
            applyRestore(save)
        }

        onGoldChanged?(goldManager.gold)
        onLivesChanged?(lives)
    }

    private func applyRestore(_ save: GameSaveState) {
        currentWaveNumber = save.wave
        waveSystem.syncWave(save.wave)
        lives = save.lives
        enemyKills = save.enemyKills
        goldManager.setGold(save.gold)

        onWaveChanged?(currentWaveNumber)
        onLivesChanged?(lives)
        onKillsChanged?(enemyKills)

        for savedTower in save.towers {
            guard let type = TowerType(rawValue: savedTower.type),
                  let slot = gridSystem.slot(at: savedTower.slotId) else { continue }
            gridSystem.placeTower(type: type, at: savedTower.slotId)
            var tower = buildTowerInstance(type: type, position: slot.position, slotId: savedTower.slotId)
            tower.level = savedTower.level
            tower.totalInvested = savedTower.totalInvested
            activeTowers.append(tower)
            towerLayer.addChild(tower.node)
            addLevelBadge(to: tower)
            let tap = SKShapeNode(circleOfRadius: 22)
            tap.fillColor = .clear; tap.strokeColor = .clear
            tap.name = "slot_\(savedTower.slotId)"; tap.position = slot.position; tap.zPosition = 6
            towerLayer.addChild(tap)
            towerSlotLayer.childNode(withName: "slot_\(savedTower.slotId)")?.isHidden = true
        }
    }

    private func buildTowerInstance(type: TowerType, position: CGPoint, slotId: Int) -> any Tower {
        switch type {
        case .bolt:      return BoltTower(position: position, slotId: slotId)
        case .frost:     return FrostTower(position: position, slotId: slotId)
        case .pierce:    return PierceTower(position: position, slotId: slotId)
        case .core:      return CoreTower(position: position, slotId: slotId)
        case .sniper:    return SniperTower(position: position, slotId: slotId)
        case .inferno:   return InfernoTower(position: position, slotId: slotId)
        case .tesla:     return TeslaTower(position: position, slotId: slotId)
        case .blast:
            let t = BlastTower(position: position, slotId: slotId)
            t.blastDamageCallback = { [weak self] center, radius, damage in
                self?.activeEnemies.filter { $0.isAlive }.forEach { e in
                    let d = hypot(e.node.position.x - center.x, e.node.position.y - center.y)
                    if d <= radius { e.applyAoeDamage(damage) }
                }
            }
            return t
        case .nova:
            let t = NovaTower(position: position, slotId: slotId)
            t.novaDamageCallback = { [weak self] center, radius, damage in
                self?.activeEnemies.filter { $0.isAlive }.forEach { e in
                    let d = hypot(e.node.position.x - center.x, e.node.position.y - center.y)
                    if d <= radius { e.applyAoeDamage(damage) }
                }
            }
            return t
        case .artillery:
            let t = ArtilleryTower(position: position, slotId: slotId)
            t.artilleryDamageCallback = { [weak self] center, radius, damage in
                self?.activeEnemies.filter { $0.isAlive }.forEach { e in
                    let d = hypot(e.node.position.x - center.x, e.node.position.y - center.y)
                    if d <= radius { e.applyAoeDamage(damage) }
                }
            }
            return t
        }
    }

    private func buildDynamicLayout() {
        // Pick a random starting layout — every run feels different from the first wave
        currentLayoutIndex = Int.random(in: 0..<totalLayoutCount)
        applyLayout(index: currentLayoutIndex)
    }

    private func applyLayout(index: Int) {
        let layout = layoutConfig(index: index)
        PathSystem.waypoints = layout.waypoints
        PathSystem.waypointLayers = layout.layers
        gridSystem.updateSlots(layout.slots)
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
        let cols = 16
        let rows = 26
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
        let thickness: CGFloat = 17  // scaled down from 24 to 17

        // Single pass: draw all segments uniformly as violet-slate corridor with dual cyan edge glow
        for i in 1..<waypoints.count {
            let from = waypoints[i-1]
            let to = waypoints[i]

            let dx = to.x - from.x
            let dy = to.y - from.y
            let len = sqrt(dx*dx + dy*dy)
            let angle = atan2(dy, dx)

            // Main filled corridor (violet-slate — clearly distinct from background grid)
            let seg = SKShapeNode(rectOf: CGSize(width: len, height: thickness), cornerRadius: 3)
            seg.fillColor = SKColor(red: 0.22, green: 0.20, blue: 0.32, alpha: 1.0)
            seg.strokeColor = SKColor.clear
            seg.position = CGPoint(x: (from.x+to.x)/2, y: (from.y+to.y)/2)
            seg.zRotation = angle
            seg.zPosition = 1.0
            pathLayer.addChild(seg)

            let perpX = -sin(angle)
            let perpY =  cos(angle)
            let midX = (from.x + to.x) / 2
            let midY = (from.y + to.y) / 2
            let halfW = thickness / 2

            // Left inner glow (2pt, strong)
            let leftInner = SKShapeNode(rectOf: CGSize(width: len, height: 2.0))
            leftInner.fillColor = SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: 0.55)
            leftInner.strokeColor = SKColor.clear
            leftInner.position = CGPoint(x: midX + perpX * (halfW - 1), y: midY + perpY * (halfW - 1))
            leftInner.zRotation = angle
            leftInner.zPosition = 1.1
            pathLayer.addChild(leftInner)

            // Left outer glow (1pt, soft)
            let leftOuter = SKShapeNode(rectOf: CGSize(width: len, height: 1.0))
            leftOuter.fillColor = SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: 0.25)
            leftOuter.strokeColor = SKColor.clear
            leftOuter.position = CGPoint(x: midX + perpX * (halfW + 1), y: midY + perpY * (halfW + 1))
            leftOuter.zRotation = angle
            leftOuter.zPosition = 1.1
            pathLayer.addChild(leftOuter)

            // Right inner glow (2pt, strong)
            let rightInner = SKShapeNode(rectOf: CGSize(width: len, height: 2.0))
            rightInner.fillColor = SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: 0.55)
            rightInner.strokeColor = SKColor.clear
            rightInner.position = CGPoint(x: midX - perpX * (halfW - 1), y: midY - perpY * (halfW - 1))
            rightInner.zRotation = angle
            rightInner.zPosition = 1.1
            pathLayer.addChild(rightInner)

            // Right outer glow (1pt, soft)
            let rightOuter = SKShapeNode(rectOf: CGSize(width: len, height: 1.0))
            rightOuter.fillColor = SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: 0.25)
            rightOuter.strokeColor = SKColor.clear
            rightOuter.position = CGPoint(x: midX - perpX * (halfW + 1), y: midY - perpY * (halfW + 1))
            rightOuter.zRotation = angle
            rightOuter.zPosition = 1.1
            pathLayer.addChild(rightOuter)
        }

        // Joints at all waypoints — filled circle cap (masks seam) + stroke accent
        for (_, point) in waypoints.enumerated() {
            let cap = SKShapeNode(circleOfRadius: thickness / 2)
            cap.fillColor = SKColor(red: 0.22, green: 0.20, blue: 0.32, alpha: 1.0)
            cap.strokeColor = SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: 0.50)
            cap.lineWidth = 1.5
            cap.position = point
            cap.zPosition = 1.0
            pathLayer.addChild(cap)
        }

        // Entry indicator — neon portal beacon (pulsing rings + right-pointing arrow)
        if let first = PathSystem.waypoints.first {
            let entryX: CGFloat = 22
            let entryY = first.y

            // Outer ring
            let outerRing = SKShapeNode(circleOfRadius: 13)
            outerRing.strokeColor = SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: 0.9)
            outerRing.fillColor = SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: 0.08)
            outerRing.lineWidth = 1.5
            outerRing.position = CGPoint(x: entryX, y: entryY)
            outerRing.zPosition = 3.0
            pathLayer.addChild(outerRing)

            // Inner ring
            let innerRing = SKShapeNode(circleOfRadius: 7)
            innerRing.strokeColor = SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: 0.7)
            innerRing.fillColor = SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: 0.25)
            innerRing.lineWidth = 1.5
            innerRing.position = CGPoint(x: entryX, y: entryY)
            innerRing.zPosition = 3.0
            pathLayer.addChild(innerRing)

            // Right-pointing arrow (chevron)
            let entryArrowPath = CGMutablePath()
            entryArrowPath.move(to: CGPoint(x: entryX + 4, y: entryY))
            entryArrowPath.addLine(to: CGPoint(x: entryX - 2, y: entryY + 5))
            entryArrowPath.move(to: CGPoint(x: entryX + 4, y: entryY))
            entryArrowPath.addLine(to: CGPoint(x: entryX - 2, y: entryY - 5))
            let entryArrow = SKShapeNode(path: entryArrowPath)
            entryArrow.strokeColor = SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: 1.0)
            entryArrow.lineWidth = 2.0
            entryArrow.lineCap = .round
            entryArrow.zPosition = 3.1
            pathLayer.addChild(entryArrow)

            // Pulse: outer ring breathes outward
            outerRing.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 1.45, duration: 1.1),
                    SKAction.fadeAlpha(to: 0.25, duration: 1.1)
                ]),
                SKAction.group([
                    SKAction.scale(to: 1.0, duration: 0.9),
                    SKAction.fadeAlpha(to: 1.0, duration: 0.9)
                ])
            ])))
        }

        // Exit indicator — danger breach point (dashed ring + right-pointing arrow)
        if let last = PathSystem.waypoints.last {
            let exitX = size.width - 22
            let exitY = last.y

            // Dashed danger ring via 6 short arc segments
            let dashCount = 6
            for i in 0..<dashCount {
                let angle = CGFloat(i) * (2 * .pi / CGFloat(dashCount))
                let arcPath = CGMutablePath()
                let r: CGFloat = 13
                arcPath.addArc(center: CGPoint(x: exitX, y: exitY),
                               radius: r,
                               startAngle: angle,
                               endAngle: angle + .pi / CGFloat(dashCount) - 0.18,
                               clockwise: false)
                let dash = SKShapeNode(path: arcPath)
                dash.strokeColor = SKColor(red: 1.0, green: 0.17, blue: 0.33, alpha: 0.85)
                dash.lineWidth = 2.5
                dash.lineCap = .round
                dash.zPosition = 3.0
                pathLayer.addChild(dash)
            }

            // Solid core dot — danger fill
            let exitCore = SKShapeNode(circleOfRadius: 5)
            exitCore.fillColor = SKColor(red: 1.0, green: 0.17, blue: 0.33, alpha: 0.35)
            exitCore.strokeColor = SKColor(red: 1.0, green: 0.17, blue: 0.33, alpha: 0.8)
            exitCore.lineWidth = 1.5
            exitCore.position = CGPoint(x: exitX, y: exitY)
            exitCore.zPosition = 3.0
            pathLayer.addChild(exitCore)

            // Right-pointing arrow (chevron)
            let exitArrowPath = CGMutablePath()
            exitArrowPath.move(to: CGPoint(x: exitX + 4, y: exitY))
            exitArrowPath.addLine(to: CGPoint(x: exitX - 2, y: exitY + 5))
            exitArrowPath.move(to: CGPoint(x: exitX + 4, y: exitY))
            exitArrowPath.addLine(to: CGPoint(x: exitX - 2, y: exitY - 5))
            let exitArrow = SKShapeNode(path: exitArrowPath)
            exitArrow.strokeColor = SKColor(red: 1.0, green: 0.17, blue: 0.33, alpha: 1.0)
            exitArrow.lineWidth = 2.0
            exitArrow.lineCap = .round
            exitArrow.zPosition = 3.1
            pathLayer.addChild(exitArrow)

            // Pulse: core throbs (alarm feel)
            exitCore.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.scale(to: 1.6, duration: 0.4),
                SKAction.scale(to: 1.0, duration: 0.4)
            ])))
        }
    }

    private func setupTowerSlots() {
        for slot in gridSystem.slots {
            let container = SKNode()
            container.position = slot.position
            container.name = "slot_\(slot.id)"

            // Square slot container 32×32pt (scaled down from 46×46)
            let bg = SKShapeNode(rectOf: CGSize(width: 32, height: 32), cornerRadius: 5)
            bg.fillColor = SKColor(red: 0.05, green: 0.09, blue: 0.14, alpha: 1.0)
            bg.strokeColor = SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: 0.55)
            bg.lineWidth = 1.0
            bg.name = "slot_\(slot.id)"
            container.addChild(bg)

            // Inner cross lines
            let hLine = SKShapeNode(rectOf: CGSize(width: 13, height: 2))
            hLine.fillColor = SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: 0.20)
            hLine.strokeColor = .clear
            container.addChild(hLine)

            let vLine = SKShapeNode(rectOf: CGSize(width: 2, height: 13))
            vLine.fillColor = SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: 0.20)
            vLine.strokeColor = .clear
            container.addChild(vLine)

            // Corner accent dots at 15pt offset from center
            let dotAngles: [CGFloat] = [.pi/4, 3 * .pi/4, 5 * .pi/4, 7 * .pi/4]
            for angle in dotAngles {
                let dot = SKShapeNode(circleOfRadius: 1.5)
                dot.fillColor = SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: 0.80)
                dot.strokeColor = .clear
                dot.position = CGPoint(x: cos(angle) * 15, y: sin(angle) * 15)
                container.addChild(dot)
            }

            // Invisible tap detector — 22pt radius (44pt diameter touch target)
            let tap = SKShapeNode(circleOfRadius: 22)
            tap.fillColor = .clear
            tap.strokeColor = .clear
            tap.name = "slot_\(slot.id)"
            container.addChild(tap)

            // Idle pulse animation: stroke alpha 0.40 → 0.65
            let breathe = SKAction.repeatForever(SKAction.sequence([
                SKAction.run { bg.strokeColor = SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: 0.40) },
                SKAction.customAction(withDuration: 1.2) { _, elapsed in
                    let t = elapsed / 1.2
                    let alpha = 0.40 + 0.25 * sin(t * .pi)
                    bg.strokeColor = SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: alpha)
                },
                SKAction.run { bg.strokeColor = SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: 0.40) },
                SKAction.customAction(withDuration: 1.2) { _, elapsed in
                    let t = elapsed / 1.2
                    let alpha = 0.40 + 0.25 * (1 - sin(t * .pi))
                    bg.strokeColor = SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: alpha)
                }
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
                        enemy.applyAoeDamage(damage)
                    }
                }
            }
            tower = blastTower
        case .frost:
            tower = FrostTower(position: slot.position, slotId: slotId)
        case .pierce:
            tower = PierceTower(position: slot.position, slotId: slotId)
        case .core:
            tower = CoreTower(position: slot.position, slotId: slotId)
        case .inferno:
            tower = InfernoTower(position: slot.position, slotId: slotId)
        case .tesla:
            tower = TeslaTower(position: slot.position, slotId: slotId)
        case .nova:
            let novaTower = NovaTower(position: slot.position, slotId: slotId)
            novaTower.novaDamageCallback = { [weak self] center, radius, damage in
                guard let self = self else { return }
                for enemy in self.activeEnemies {
                    guard enemy.isAlive else { continue }
                    let dx = enemy.node.position.x - center.x
                    let dy = enemy.node.position.y - center.y
                    if sqrt(dx * dx + dy * dy) <= radius {
                        enemy.applyAoeDamage(damage)
                    }
                }
            }
            tower = novaTower
        case .sniper:
            tower = SniperTower(position: slot.position, slotId: slotId)
        case .artillery:
            let artTower = ArtilleryTower(position: slot.position, slotId: slotId)
            artTower.artilleryDamageCallback = { [weak self] center, radius, damage in
                guard let self = self else { return }
                for enemy in self.activeEnemies {
                    guard enemy.isAlive else { continue }
                    let dx = enemy.node.position.x - center.x
                    let dy = enemy.node.position.y - center.y
                    if sqrt(dx * dx + dy * dy) <= radius {
                        enemy.applyAoeDamage(damage)
                    }
                }
            }
            tower = artTower
        }

        activeTowers.append(tower)
        towerLayer.addChild(tower.node)
        addLevelBadge(to: tower)

        // Hidden slot node is NOT hit-testable — add transparent tap detector instead.
        let tapDetector = SKShapeNode(circleOfRadius: 22)
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
        guard currentBatchIndex < currentSpawnBatches.count else { return }

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
        case .shield:
            enemy = ShieldEnemy(hpMultiplier: hpMult)
        case .swarm:
            enemy = SwarmEnemy(hpMultiplier: hpMult)
        case .ghost:
            enemy = GhostEnemy(hpMultiplier: hpMult)
        case .splitter:
            enemy = SplitterEnemy(hpMultiplier: hpMult)
        case .jumper:
            enemy = JumperEnemy(hpMultiplier: hpMult)
        case .healer:
            enemy = HealerEnemy(hpMultiplier: hpMult)
        case .phantom:
            enemy = PhantomEnemy(hpMultiplier: hpMult)
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

        let adjustedDelta = deltaTime * speedMultiplier

        if isWaveActive {
            timeSinceLastSpawn += adjustedDelta
            if timeSinceLastSpawn >= spawnInterval {
                timeSinceLastSpawn = 0
                spawnNextEnemy()
            }
        }

        updateEnemies(deltaTime: adjustedDelta, currentTime: currentTime)
        updateTowers(currentTime: currentTime)
        checkWaveCompletion()
    }

    func setSpeedMultiplier(_ mult: Double) {
        speedMultiplier = mult
        onSpeedChanged?(mult)
    }

    private func updateEnemies(deltaTime: TimeInterval, currentTime: TimeInterval) {
        var deadIndices: [Int] = []
        var endReachedIndices: [Int] = []

        for (idx, enemy) in activeEnemies.enumerated() {
            enemy.updateSlowEffect(currentTime: currentTime)
            enemy.updateMovement(deltaTime: deltaTime)

            // Boss special abilities
            if let boss = enemy as? BossEnemy {
                boss.tickAbility(currentTime: currentTime, scene: self)
            }
            // Healer aura
            if let healer = enemy as? HealerEnemy {
                healer.tickHeal(currentTime: currentTime, allEnemies: activeEnemies)
            }

            if enemy.isDead {
                deadIndices.append(idx)
                let cycle = waveSystem.cycleNumber(for: currentWaveNumber)
                let cycleScale = EconomyConstants.killGoldMultiplier(forCycle: cycle)
                let scaledGold = max(1, Int(Double(enemy.goldReward) * cycleScale))
                goldManager.earn(scaledGold)
                enemyKills += 1
                waveEnemiesCleared += 1
                onKillsChanged?(enemyKills)
                onWaveProgress?(waveEnemiesCleared, waveEnemyTotal)
                // Splitter spawns 2 Swarm children on death
                if enemy.type == .splitter {
                    spawnSplitterChildren(at: enemy.pathProgress, position: enemy.node.position)
                }
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

            // Rotate tower to face target before firing — barrel points up (+y) by default,
            // so offset atan2 by -π/2 to align the barrel with the direction to enemy.
            let dx = target.node.position.x - tower.position.x
            let dy = target.node.position.y - tower.position.y
            let angle = atan2(dy, dx) - .pi / 2
            tower.node.run(SKAction.rotate(toAngle: angle, duration: 0.08, shortestUnitArc: true))

            tower.fire(at: target, scene: self, currentTime: currentTime)
        }
    }

    private func isEnemy(_ enemy: any EnemyNode, inRangeOf tower: any Tower) -> Bool {
        let dx = enemy.node.position.x - tower.position.x
        let dy = enemy.node.position.y - tower.position.y
        let inRange = sqrt(dx * dx + dy * dy) <= tower.type.range
        guard inRange else { return false }

        switch tower.type.targetingMode {
        case .allLayers:  return true
        case .groundOnly: return enemy.pathLayer == .ground
        case .bridgeOnly:
            // If current layout has no bridge segments, fall back to all layers
            let hasBridges = PathSystem.waypointLayers.contains(.bridge)
            return hasBridges ? enemy.pathLayer == .bridge : true
        }
    }

    private func checkWaveCompletion() {
        guard isWaveActive else { return }
        let noMoreSpawns = currentBatchIndex >= currentSpawnBatches.count && remainingInCurrentBatch <= 0
        let noActiveEnemies = activeEnemies.filter { $0.isAlive }.isEmpty

        if noMoreSpawns && noActiveEnemies {
            isWaveActive = false
            goldManager.awardWaveReward(wave: currentWaveNumber)
            onWaveComplete?(currentWaveNumber)

            // Diamond reward every 10 waves
            if currentWaveNumber % 10 == 0 {
                let reward: Int
                switch currentWaveNumber {
                case 1...30:  reward = 2
                case 31...60: reward = 3
                default:      reward = 4
                }
                DiamondStore.shared.earn(reward)
                onDiamondsChanged?(DiamondStore.shared.balance)
            }

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
            if PremiumStore.shared.isPremium && !hasUsedRevive {
                isPaused = true
                onReviveAvailable?()
            } else {
                triggerGameOver()
            }
        }
    }

    func acceptRevive() {
        hasUsedRevive = true
        lives = 1
        onLivesChanged?(lives)
        isPaused = false
    }

    func declineRevive() {
        triggerGameOver()
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
        let badge = SKShapeNode(circleOfRadius: 5)
        badge.fillColor = SKColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 0.95)
        badge.strokeColor = SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: 0.9)
        badge.lineWidth = 1
        badge.name = "levelBadge"
        badge.position = CGPoint(x: 10, y: -10)
        badge.zPosition = 2
        let lbl = SKLabelNode(text: "1")
        lbl.fontSize = 6
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

    // MARK: - Map Layouts

    // MARK: - Layout System (18 layouts: 12 Z-shape + 6 crossing)

    // Derives slot positions algorithmically so they NEVER land on the path.
    // Works for both forward (y1<y2<y3) and reverse (y1>y2>y3) Z-shapes.
    private func computeSlots(y1: CGFloat, y2: CGFloat, y3: CGFloat,
                               xL: CGFloat, xR: CGFloat) -> [CGPoint] {
        let W = size.width
        let vGap: CGFloat = 88   // vertical clearance from horizontal segment
        let hGap: CGFloat = 64   // horizontal clearance from vertical segment
        let edge: CGFloat = 30   // minimum distance from screen edge
        let minSep: CGFloat = 52 // minimum slot-to-slot distance

        let fwd = y1 < y2
        let seg1Side = y1 + (fwd ?  vGap : -vGap)
        let seg3Side = y2 + (fwd ? -vGap :  vGap)
        let seg5Side = y3 + (fwd ? -vGap :  vGap)
        let srx = min(xR + hGap, W - edge)

        // Ordered so far-end (seg5 / right zone) candidates come FIRST →
        // prefix(activeSlotCount) always includes right-side coverage.
        let cands: [CGPoint] = [
            // ─── FAR END — last horizontal (seg5) and right-of-screen zone ───
            CGPoint(x: min(W - edge, W*0.86),           y: seg5Side),           // far right
            CGPoint(x: min(W*0.72, W - edge),           y: seg5Side),           // right-centre
            CGPoint(x: (xL + W) * 0.5,                  y: seg5Side),           // midpoint of exit path
            CGPoint(x: srx,                              y: y2 + (y3-y2)*0.50), // open right mid
            // ─── MID-RIGHT — right vertical (seg2) ───
            CGPoint(x: srx, y: y1 + (y2-y1)*0.27),
            CGPoint(x: srx, y: y1 + (y2-y1)*0.73),
            // ─── MIDDLE — middle horizontal (seg3) ───
            CGPoint(x: max(W*0.38, xL+hGap+10),         y: seg3Side),
            CGPoint(x: min(W*0.62, xR-hGap-10),         y: seg3Side),
            // ─── MID-LEFT — left vertical (seg4) ───
            CGPoint(x: xL + hGap, y: y2 + (y3-y2)*0.33),
            CGPoint(x: xL + hGap, y: y2 + (y3-y2)*0.68),
            // ─── NEAR START — first horizontal (seg1) ───
            CGPoint(x: W*0.14,                           y: seg1Side),
            CGPoint(x: W*0.38,                           y: seg1Side),
            CGPoint(x: min(W*0.62, xR-hGap-8),          y: seg1Side),
        ]

        var result: [CGPoint] = []
        for c in cands {
            guard c.x >= edge, c.x <= W - edge,
                  c.y >= contentMinY + edge, c.y <= contentMaxY - edge else { continue }
            let tooClose = result.contains { e in hypot(c.x - e.x, c.y - e.y) < minSep }
            if !tooClose { result.append(c) }
        }
        return Array(result.prefix(activeSlotCount()))
    }

    /// Guarantees at least one slot near each of the 3 path segments.
    /// Splits the waypoint list into 3 even groups and injects a safe fallback
    /// slot 80 pt perpendicular to the segment midpoint when a zone has no coverage.
    private func guaranteePathCoverage(slots: [CGPoint], waypoints: [CGPoint]) -> [CGPoint] {
        guard waypoints.count >= 2 else { return slots }
        let W = size.width
        let edge: CGFloat = 30
        let nearDist: CGFloat = 100   // "near segment" threshold
        let offsetDist: CGFloat = 80  // perpendicular offset for injected slot
        let minSep: CGFloat = 56

        // Divide waypoint pairs into 3 roughly-equal segment groups
        let pairs = waypoints.count - 1           // number of segments
        let zoneSize = max(1, pairs / 3)
        let zones: [(Int, Int)] = [
            (0,            zoneSize - 1),
            (zoneSize,     zoneSize * 2 - 1),
            (zoneSize * 2, pairs - 1)
        ]

        var result = slots

        for (startSeg, endSeg) in zones {
            // Check if any existing slot is within nearDist of any segment in this zone
            var covered = false
            outer: for si in startSeg...endSeg {
                let a = waypoints[si], b = waypoints[si + 1]
                for slot in result {
                    if pointToSegmentDist(slot, a: a, b: b) < nearDist {
                        covered = true
                        break outer
                    }
                }
            }
            guard !covered else { continue }

            // Find midpoint of the middle segment in this zone
            let midSeg = (startSeg + endSeg) / 2
            let a = waypoints[midSeg], b = waypoints[midSeg + 1]
            let mx = (a.x + b.x) / 2
            let my = (a.y + b.y) / 2
            let dx = b.x - a.x, dy = b.y - a.y
            let len = max(hypot(dx, dy), 1)
            // Perpendicular unit vector (rotate 90°)
            let px = -dy / len, py = dx / len

            // Try both sides of the path; pick whichever is in-bounds
            // Insert at front so prefix(activeSlotCount) never cuts guaranteed slots
            for sign: CGFloat in [1, -1] {
                let cx = mx + px * offsetDist * sign
                let cy = my + py * offsetDist * sign
                guard cx >= edge, cx <= W - edge,
                      cy >= contentMinY + edge, cy <= contentMaxY - edge else { continue }
                let tooClose = result.contains { hypot($0.x - cx, $0.y - cy) < minSep }
                if !tooClose {
                    result.insert(CGPoint(x: cx, y: cy), at: 0)
                    break
                }
            }
        }

        return result
    }

    /// Ensures the slots array has at least `activeSlotCount()` entries.
    /// If fewer exist, generates emergency fallback positions offset from path midpoints.
    private func ensureMinimumSlots(_ slots: [CGPoint], waypoints: [CGPoint]) -> [CGPoint] {
        let needed = activeSlotCount()
        guard slots.count < needed else { return Array(slots.prefix(needed)) }
        var result = slots
        let shortfall = needed - result.count
        let offsets: [CGFloat] = [80, -80, 110, -110, 60, -60, 130, -130]
        var added = 0
        for step in stride(from: 0, to: waypoints.count - 1, by: 1) {
            guard added < shortfall else { break }
            let a = waypoints[step], b = waypoints[step + 1]
            let mid = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
            let dx = b.x - a.x, dy = b.y - a.y
            let len = max(1, sqrt(dx*dx + dy*dy))
            let perpX = -dy / len, perpY = dx / len  // unit perpendicular
            for off in offsets {
                guard added < shortfall else { break }
                let candidate = CGPoint(x: mid.x + perpX * off, y: mid.y + perpY * off)
                guard candidate.x > 20, candidate.x < size.width - 20 else { continue }
                guard candidate.y > contentMinY + 20, candidate.y < contentMaxY - 20 else { continue }
                let tooClose = result.contains { hypot($0.x - candidate.x, $0.y - candidate.y) < 48 }
                guard !tooClose else { continue }
                guard isSlotClearOfPath(candidate, waypoints: waypoints, clearance: 20) else { continue }
                result.append(candidate)
                added += 1
            }
        }
        return result
    }

    /// Perpendicular distance from point `p` to segment `a→b`.
    private func pointToSegmentDist(_ p: CGPoint, a: CGPoint, b: CGPoint) -> CGFloat {
        let dx = b.x - a.x, dy = b.y - a.y
        let lenSq = dx*dx + dy*dy
        if lenSq == 0 { return hypot(p.x - a.x, p.y - a.y) }
        let t = max(0, min(1, ((p.x - a.x)*dx + (p.y - a.y)*dy) / lenSq))
        return hypot(p.x - (a.x + t*dx), p.y - (a.y + t*dy))
    }

    /// Returns true if `slot` is at least `clearance` pixels away from every path segment.
    private func isSlotClearOfPath(_ slot: CGPoint, waypoints: [CGPoint], clearance: CGFloat = 28) -> Bool {
        guard waypoints.count >= 2 else { return true }
        for i in 1..<waypoints.count {
            if pointToSegmentDist(slot, a: waypoints[i-1], b: waypoints[i]) < clearance {
                return false
            }
        }
        return true
    }

    // 18 Z-layout parameter sets — (y1%, y2%, y3%, xL%, xR%) as fractions of H/W.
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
        // --- 6 new creative Z-variants ---
        (0.10, 0.35, 0.60, 0.22, 0.78),   // 12: zigzag upper-bias
        (0.40, 0.65, 0.90, 0.20, 0.80),   // 13: zigzag lower-bias
        (0.85, 0.55, 0.25, 0.20, 0.80),   // 14: wide diagonal reverse
        (0.22, 0.48, 0.74, 0.20, 0.55),   // 15: left-skewed forward
        (0.76, 0.52, 0.28, 0.45, 0.80),   // 16: right-skewed reverse
        (0.14, 0.42, 0.86, 0.30, 0.70),   // 17: tall narrow Z
    ]

    /// Total layout count: 18 Z-layouts + 6 crossing layouts = 24.
    private var totalLayoutCount: Int { layoutParams.count + 6 }

    private func layoutConfig(index: Int) -> (waypoints: [CGPoint], layers: [PathLayer], slots: [CGPoint]) {
        let safeIndex = index % totalLayoutCount
        if safeIndex < layoutParams.count {
            // Z-layout — all ground
            let H = contentHeight   // use inset height
            let CW = contentWidth   // use inset width
            let yBase = contentMinY // SpriteKit y-offset
            let xOffset = (size.width - CW) / 2  // center the path within content area

            let p = layoutParams[safeIndex]
            let y1 = yBase + H*p.0
            let y2 = yBase + H*p.1
            let y3 = yBase + H*p.2
            let xL = xOffset + CW*p.3
            let xR = xOffset + CW*p.4

            let waypoints: [CGPoint] = [
                CGPoint(x: xOffset - 10,       y: y1),
                CGPoint(x: xR,                 y: y1),
                CGPoint(x: xR,                 y: y2),
                CGPoint(x: xL,                 y: y2),
                CGPoint(x: xL,                 y: y3),
                CGPoint(x: xOffset + CW + 10,  y: y3),
            ]
            let layers: [PathLayer] = Array(repeating: .ground, count: waypoints.count)
            let rawSlots = computeSlots(y1: y1, y2: y2, y3: y3, xL: xL, xR: xR)
            let pathClearSlots = rawSlots.filter { isSlotClearOfPath($0, waypoints: waypoints, clearance: 28) }
            let guaranteedSlots = guaranteePathCoverage(slots: pathClearSlots, waypoints: waypoints)
            let finalSlots = ensureMinimumSlots(guaranteedSlots, waypoints: waypoints)
            return (waypoints, layers, finalSlots)
        } else {
            // Crossing layout
            return crossLayoutConfig(index: safeIndex - layoutParams.count)
        }
    }

    // MARK: - Crossing Layouts (indices 18–23)

    /// Generates slots for an arbitrary waypoint path using perpendicular offsets.
    private func computeSlotsForPath(waypoints: [CGPoint]) -> [CGPoint] {
        guard waypoints.count >= 2 else { return [] }
        let W = size.width
        let edge: CGFloat = 30
        let minSep: CGFloat = 56
        let offsetDist: CGFloat = 80

        var cands: [CGPoint] = []
        for i in 0..<(waypoints.count - 1) {
            let a = waypoints[i], b = waypoints[i + 1]
            let dx = b.x - a.x, dy = b.y - a.y
            let len = max(hypot(dx, dy), 1)
            let px = -dy / len, py = dx / len   // perpendicular unit vector

            // Candidate at 1/3, 1/2, 2/3 along segment — both perpendicular sides
            for t: CGFloat in [0.33, 0.5, 0.67] {
                let mx = a.x + dx * t, my = a.y + dy * t
                for sign: CGFloat in [1, -1] {
                    cands.append(CGPoint(x: mx + px * offsetDist * sign,
                                        y: my + py * offsetDist * sign))
                }
            }
        }

        var result: [CGPoint] = []
        for c in cands {
            guard c.x >= edge, c.x <= W - edge,
                  c.y >= contentMinY + edge, c.y <= contentMaxY - edge else { continue }
            let tooClose = result.contains { hypot($0.x - c.x, $0.y - c.y) < minSep }
            if !tooClose { result.append(c) }
        }
        let pathClear = result.filter { isSlotClearOfPath($0, waypoints: waypoints, clearance: 28) }
        let raw = Array(pathClear.prefix(activeSlotCount()))
        return guaranteePathCoverage(slots: raw, waypoints: waypoints)
    }

    // Bridge waypoint layers for each crossing layout (same index as cross-0..5)
    // Bridge distinction is visual-only in game logic — all ground visually since Build 5.2
    private let crossLayoutBridgeLayers: [[PathLayer]] = [
        // cross-0 S-curve: all ground visually
        [.ground, .ground, .ground, .ground, .ground, .ground, .ground],
        // cross-1 X-Cross: all ground visually
        [.ground, .ground, .ground, .ground, .ground, .ground, .ground, .ground],
        // cross-2 Double-Z: all ground visually
        [.ground, .ground, .ground, .ground, .ground, .ground, .ground, .ground],
        // cross-3 Spiral: all ground visually
        [.ground, .ground, .ground, .ground, .ground, .ground, .ground],
        // cross-4 W-shape: all ground visually
        [.ground, .ground, .ground, .ground, .ground, .ground, .ground, .ground],
        // cross-5 Diagonal: all ground visually
        [.ground, .ground, .ground, .ground, .ground, .ground],
    ]

    private func crossLayoutConfig(index: Int) -> (waypoints: [CGPoint], layers: [PathLayer], slots: [CGPoint]) {
        let CH = contentHeight   // use inset height
        let CW = contentWidth    // use inset width
        let yBase = contentMinY  // SpriteKit y-offset
        let xOff = (size.width - CW) / 2  // center path within content area

        // Helper to convert fractional coordinates to content-area absolute positions
        func cx(_ f: CGFloat) -> CGFloat { xOff + CW * f }
        func cy(_ f: CGFloat) -> CGFloat { yBase + CH * f }

        let waypoints: [CGPoint]
        switch index % 6 {
        case 0:
            // Cross-0: Figure-S (smooth horizontal S-curve, no self-intersection)
            waypoints = [
                CGPoint(x: xOff - 10,  y: cy(0.50)),
                CGPoint(x: cx(0.15),   y: cy(0.50)),
                CGPoint(x: cx(0.25),   y: cy(0.20)),
                CGPoint(x: cx(0.50),   y: cy(0.50)),
                CGPoint(x: cx(0.75),   y: cy(0.80)),
                CGPoint(x: cx(0.85),   y: cy(0.50)),
                CGPoint(x: xOff+CW+10, y: cy(0.50)),
            ]
        case 1:
            // Cross-1: X-Cross (diamond loop — path passes through mid twice)
            waypoints = [
                CGPoint(x: xOff - 10,  y: cy(0.50)),
                CGPoint(x: cx(0.20),   y: cy(0.50)),
                CGPoint(x: cx(0.40),   y: cy(0.15)),
                CGPoint(x: cx(0.60),   y: cy(0.50)),
                CGPoint(x: cx(0.40),   y: cy(0.85)),
                CGPoint(x: cx(0.60),   y: cy(0.50)),
                CGPoint(x: cx(0.80),   y: cy(0.50)),
                CGPoint(x: xOff+CW+10, y: cy(0.50)),
            ]
        case 2:
            // Cross-2: Double-Z (two Z-zigzags chained)
            waypoints = [
                CGPoint(x: xOff - 10,  y: cy(0.20)),
                CGPoint(x: cx(0.30),   y: cy(0.20)),
                CGPoint(x: cx(0.50),   y: cy(0.50)),
                CGPoint(x: cx(0.20),   y: cy(0.50)),
                CGPoint(x: cx(0.40),   y: cy(0.80)),
                CGPoint(x: cx(0.70),   y: cy(0.80)),
                CGPoint(x: cx(0.80),   y: cy(0.50)),
                CGPoint(x: xOff+CW+10, y: cy(0.50)),
            ]
        case 3:
            // Cross-3: Spiral approach (U-turn near top, then diagonal exit)
            waypoints = [
                CGPoint(x: xOff - 10,  y: cy(0.75)),
                CGPoint(x: cx(0.50),   y: cy(0.75)),
                CGPoint(x: cx(0.50),   y: cy(0.25)),
                CGPoint(x: cx(0.20),   y: cy(0.25)),
                CGPoint(x: cx(0.20),   y: cy(0.55)),
                CGPoint(x: cx(0.70),   y: cy(0.55)),
                CGPoint(x: xOff+CW+10, y: cy(0.55)),
            ]
        case 4:
            // Cross-4: W-shape (three dips)
            waypoints = [
                CGPoint(x: xOff - 10,  y: cy(0.50)),
                CGPoint(x: cx(0.10),   y: cy(0.50)),
                CGPoint(x: cx(0.20),   y: cy(0.15)),
                CGPoint(x: cx(0.40),   y: cy(0.55)),
                CGPoint(x: cx(0.60),   y: cy(0.15)),
                CGPoint(x: cx(0.80),   y: cy(0.55)),
                CGPoint(x: cx(0.90),   y: cy(0.50)),
                CGPoint(x: xOff+CW+10, y: cy(0.50)),
            ]
        default: // case 5:
            // Cross-5: Long diagonal reverse (top-right then bottom-right)
            waypoints = [
                CGPoint(x: xOff - 10,  y: cy(0.20)),
                CGPoint(x: cx(0.30),   y: cy(0.20)),
                CGPoint(x: cx(0.60),   y: cy(0.20)),
                CGPoint(x: cx(0.40),   y: cy(0.80)),
                CGPoint(x: cx(0.70),   y: cy(0.80)),
                CGPoint(x: xOff+CW+10, y: cy(0.80)),
            ]
        }
        let rawCrossSlots = computeSlotsForPath(waypoints: waypoints)
        let slots = ensureMinimumSlots(rawCrossSlots, waypoints: waypoints)
        let crossIdx = index % 6
        var layers: [PathLayer]
        if crossIdx < crossLayoutBridgeLayers.count {
            let template = crossLayoutBridgeLayers[crossIdx]
            // Clamp to actual waypoint count to be safe
            layers = (0..<waypoints.count).map { i in
                i < template.count ? template[i] : .ground
            }
        } else {
            layers = Array(repeating: .ground, count: waypoints.count)
        }
        return (waypoints, layers, slots)
    }

    private func performRiftShift() {
        // Pick a completely different layout — never repeat the same one
        var newIndex = Int.random(in: 0..<totalLayoutCount)
        if newIndex == currentLayoutIndex {
            newIndex = (newIndex + 1 + Int.random(in: 1..<totalLayoutCount)) % totalLayoutCount
        }
        currentLayoutIndex = newIndex
        let layout = layoutConfig(index: newIndex)

        // Update path and slot data
        PathSystem.waypoints = layout.waypoints
        PathSystem.waypointLayers = layout.layers
        let towerSnapshot = activeTowers.map { (slotId: $0.slotId, type: $0.type, tower: $0) }
        gridSystem.updateSlots(layout.slots)

        // Redraw map
        pathLayer.removeAllChildren()
        towerSlotLayer.removeAllChildren()
        setupPath()
        setupTowerSlots()

        // Decide which towers survive the Rift
        // Each tower independently: 60% survive, 40% destroyed. Always keep ≥1.
        // Deterministic survival: 65% of towers survive, minimum 2 (or all if ≤2).
        // Shuffle then take prefix — no "unlucky wipe" possible.
        let n = towerSnapshot.count
        let survivorCount = n <= 2 ? n : min(n, max(2, Int(ceil(Double(n) * 0.65))))
        let shuffled = towerSnapshot.shuffled()
        let survivors     = Array(shuffled.prefix(survivorCount))
        let destroyedTowers = Array(shuffled.dropFirst(survivorCount))

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
            let tapDet = SKShapeNode(circleOfRadius: 22)
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

    // MARK: - Splitter Children Spawner

    private func spawnSplitterChildren(at progress: CGFloat, position: CGPoint) {
        let hpMult = waveSystem.hpScaleMultiplier(for: currentWaveNumber)
        for _ in 0..<2 {
            let swarm = SwarmEnemy(hpMultiplier: hpMult)
            swarm.pathProgress = progress
            swarm.node.position = position
            activeEnemies.append(swarm)
            enemyLayer.addChild(swarm.node)
            waveEnemyTotal += 1
            onWaveProgress?(waveEnemiesCleared, waveEnemyTotal)
        }
    }

    // MARK: - Tesla Chain Damage Helper

    func applyChainDamage(from center: CGPoint, excluding excludedEnemy: any EnemyNode, radius: CGFloat, damage: CGFloat) {
        let chainTargets = activeEnemies.filter { target in
            guard target.isAlive && target !== excludedEnemy else { return false }
            let dx = target.node.position.x - center.x
            let dy = target.node.position.y - center.y
            return sqrt(dx * dx + dy * dy) <= radius
        }.prefix(2)

        for chainTarget in chainTargets {
            chainTarget.applyDamage(damage)
        }
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

    // MARK: - Boss Ability Helpers

    /// Rift Guardian: slows all tower attack rates by 60% for `duration` seconds
    func triggerRiftPulse(duration: TimeInterval) {
        towerAttackSpeedDebuffActive = true
        // Tint towers purple during debuff
        for tower in activeTowers {
            tower.node.run(SKAction.colorize(with: SKColor(red: 0.55, green: 0.0, blue: 1.0, alpha: 1), colorBlendFactor: 0.5, duration: 0.2))
        }
        // Apply debuff by extending lastFiredTime for all towers
        for tower in activeTowers {
            tower.lastFiredTime += duration
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            guard let self = self else { return }
            self.towerAttackSpeedDebuffActive = false
            for tower in self.activeTowers {
                tower.node.run(SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.3))
            }
        }
    }

    /// Swarm Queen: spawns `count` Swarm enemies at the given path progress position
    func spawnBroodBurst(at progress: CGFloat, count: Int) {
        let hpMult = waveSystem.hpScaleMultiplier(for: currentWaveNumber)
        let spawnPos = PathSystem.position(at: progress)
        for i in 0..<count {
            let swarm = SwarmEnemy(hpMultiplier: hpMult)
            swarm.pathProgress = progress
            // Slight stagger so they don't all sit on exactly the same point
            let offset = CGFloat(i) * 0.002
            swarm.pathProgress = min(1.0, progress + offset)
            swarm.node.position = spawnPos
            // Brief burst animation
            swarm.node.setScale(0.1)
            swarm.node.run(SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 1.0, duration: 0.2),
                    SKAction.moveBy(x: CGFloat.random(in: -15...15), y: CGFloat.random(in: -15...15), duration: 0.2)
                ])
            ]))
            activeEnemies.append(swarm)
            enemyLayer.addChild(swarm.node)
            waveEnemyTotal += 1
            onWaveProgress?(waveEnemiesCleared, waveEnemyTotal)
        }
    }

    /// Phase Runner: resets boss speed to baseSpeed after `delay` seconds
    func scheduleReset(for boss: BossEnemy, after delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak boss] in
            guard let boss = boss else { return }
            boss.currentSpeed = boss.baseSpeed
        }
    }

    /// Void Titan: destroys all in-flight projectiles + disables nearby towers for `duration`
    func triggerGravityWell(duration: TimeInterval) {
        // Remove all projectile-like nodes from effectLayer (they are short-lived SKShapeNode children)
        effectLayer.children
            .filter { $0.name == "projectile" }
            .forEach { $0.removeFromParent() }
        // Disable all towers briefly via lastFiredTime extension
        for tower in activeTowers {
            tower.lastFiredTime = max(tower.lastFiredTime, CACurrentMediaTime() + duration)
            tower.node.run(SKAction.sequence([
                SKAction.colorize(with: SKColor(red: 0.3, green: 0.0, blue: 0.5, alpha: 1), colorBlendFactor: 0.6, duration: 0.1),
                SKAction.wait(forDuration: duration - 0.2),
                SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.2)
            ]))
        }
        // Visual: expanding dark purple ring
        let ring = SKShapeNode(circleOfRadius: 10)
        ring.strokeColor = SKColor(red: 0.4, green: 0.0, blue: 0.7, alpha: 0.8)
        ring.fillColor = SKColor(red: 0.2, green: 0.0, blue: 0.4, alpha: 0.2)
        ring.lineWidth = 2
        // Position at void titan if alive
        if let titan = activeEnemies.first(where: { ($0 as? BossEnemy)?.bossVariant == 4 }) {
            ring.position = titan.node.position
        } else {
            ring.position = CGPoint(x: size.width / 2, y: size.height / 2)
        }
        ring.zPosition = 6
        effectLayer.addChild(ring)
        ring.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 25.0, duration: 0.4),
                SKAction.fadeOut(withDuration: 0.4)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Tower-Path Overlap Prevention

    private func isSlotOverlappingPath(_ position: CGPoint) -> Bool {
        let waypoints = PathSystem.waypoints
        guard waypoints.count >= 2 else { return false }
        let minDistance: CGFloat = 28  // slot half=16 + path half=8.5 + buffer=3.5
        for i in 0..<(waypoints.count - 1) {
            let dist = distanceFromPoint(position, toSegment: waypoints[i], waypoints[i+1])
            if dist < minDistance { return true }
        }
        return false
    }

    private func distanceFromPoint(_ p: CGPoint, toSegment a: CGPoint, _ b: CGPoint) -> CGFloat {
        let ab = CGPoint(x: b.x - a.x, y: b.y - a.y)
        let ap = CGPoint(x: p.x - a.x, y: p.y - a.y)
        let lenSq = ab.x * ab.x + ab.y * ab.y
        if lenSq == 0 { return hypot(p.x - a.x, p.y - a.y) }
        let t = max(0, min(1, (ap.x * ab.x + ap.y * ab.y) / lenSq))
        let closest = CGPoint(x: a.x + t * ab.x, y: a.y + t * ab.y)
        return hypot(p.x - closest.x, p.y - closest.y)
    }
}
