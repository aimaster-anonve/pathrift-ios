import Foundation
import CoreGraphics
import SpriteKit

final class BossEnemy: EnemyNode {
    let type: EnemyType = .boss
    let maxHP: CGFloat
    var currentHP: CGFloat
    let baseSpeed: CGFloat
    var currentSpeed: CGFloat
    var armor: CGFloat
    var goldReward: Int = 120
    var pathProgress: CGFloat = 0
    var hasReachedEnd: Bool = false
    var slowTimer: TimeInterval = 0
    var pathLayer: PathLayer = .ground
    let node: SKNode
    let bossVariant: Int  // 0-4, cycles through 5 distinct bosses

    // MARK: - Boss Special Ability State
    var abilityTriggered: Bool = false
    var shellActive: Bool = false
    var shellTimer: TimeInterval = 0
    var gravityWellTimer: TimeInterval = 0

    init(waveNumber: Int) {
        let bossIndex = (waveNumber / 10 - 1) % 5   // cycles through 5 variants
        let cycle = waveNumber / 50                   // HP boost every 50 waves
        let baseHp = CGFloat(800 + (waveNumber / 10) * 300 + cycle * 500)
        self.bossVariant = bossIndex
        self.maxHP = baseHp
        self.currentHP = baseHp

        switch bossIndex {
        case 1: // Iron Colossus — heavily armored, very slow
            self.baseSpeed = 22
            self.currentSpeed = 22
            self.armor = 0.50
        case 2: // Swarm Queen — fast, light armor
            self.baseSpeed = 50
            self.currentSpeed = 50
            self.armor = 0.10
        case 3: // Phase Runner — fastest boss, minimal armor
            self.baseSpeed = 70
            self.currentSpeed = 70
            self.armor = 0.05
        case 4: // Void Titan — massive, heavy armor
            self.baseSpeed = 18
            self.currentSpeed = 18
            self.armor = 0.60
        default: // 0: Rift Guardian — standard purple spiky boss
            self.baseSpeed = 32
            self.currentSpeed = 32
            self.armor = 0.30
        }

        self.node = BossEnemy.makeNode(variant: bossIndex, waveNumber: waveNumber)
        self.node.position = PathSystem.waypoints.first ?? .zero
    }

    // Override refreshHealthBar for the wider 56pt boss health bar
    func refreshHealthBar() {
        guard let bar = node.childNode(withName: "healthBar") as? SKShapeNode else { return }
        let ratio = max(0, currentHP / maxHP)
        let totalWidth: CGFloat = 56
        let filledWidth = totalWidth * ratio

        let path = CGMutablePath()
        path.addRect(CGRect(x: -totalWidth / 2, y: 0, width: filledWidth, height: 7))
        bar.path = path

        let color: SKColor
        switch bossVariant {
        case 1: color = ratio > 0.5 ? SKColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1) : SKColor.red
        case 2: color = ratio > 0.5 ? SKColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1) : SKColor.red
        case 3: color = ratio > 0.5 ? SKColor(red: 0.0, green: 0.9, blue: 0.9, alpha: 1) : SKColor.red
        case 4: color = ratio > 0.5 ? SKColor(red: 0.6, green: 0.0, blue: 0.8, alpha: 1) : SKColor.red
        default: color = ratio > 0.5 ? SKColor(red: 0.6, green: 0.3, blue: 1.0, alpha: 1) : SKColor.red
        }
        bar.fillColor = color
    }

    private static func makeNode(variant: Int, waveNumber: Int) -> SKNode {
        let container = SKNode()
        container.zPosition = 4

        // Wide health bar background (56pt) — added to root container (static UI)
        let bgPath = CGMutablePath()
        bgPath.addRect(CGRect(x: -28, y: 0, width: 56, height: 7))
        let bg = SKShapeNode(path: bgPath)
        bg.fillColor = SKColor.darkGray
        bg.strokeColor = SKColor.clear
        bg.name = "healthBarBg"
        bg.position = CGPoint(x: 0, y: 38)
        container.addChild(bg)

        let barPath = CGMutablePath()
        barPath.addRect(CGRect(x: -28, y: 0, width: 56, height: 7))
        let bar = SKShapeNode(path: barPath)
        bar.strokeColor = SKColor.clear
        bar.name = "healthBar"
        bar.position = CGPoint(x: 0, y: 38)
        container.addChild(bar)

        // Boss number label
        let bossNum = waveNumber / 10
        let numLabel = SKLabelNode(text: "#\(bossNum)")
        numLabel.fontSize = 8
        numLabel.fontName = "AvenirNext-Bold"
        numLabel.fontColor = SKColor(white: 1, alpha: 0.7)
        numLabel.verticalAlignmentMode = .center
        numLabel.horizontalAlignmentMode = .center
        numLabel.position = CGPoint(x: 0, y: 50)
        container.addChild(numLabel)

        // Variant-specific visuals
        switch variant {
        case 1: // Iron Colossus — grey armored square, 50% armor
            bar.fillColor = SKColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1)
            let hull = SKShapeNode(rectOf: CGSize(width: 38, height: 38), cornerRadius: 5)
            hull.fillColor = SKColor(red: 0.4, green: 0.4, blue: 0.45, alpha: 1)
            hull.strokeColor = SKColor(red: 0.7, green: 0.7, blue: 0.8, alpha: 1)
            hull.lineWidth = 3
            container.addChild(hull)
            let plates = SKShapeNode(rectOf: CGSize(width: 32, height: 12), cornerRadius: 2)
            plates.fillColor = SKColor(red: 0.5, green: 0.5, blue: 0.55, alpha: 1)
            plates.strokeColor = SKColor.clear
            container.addChild(plates)
            let nameLabel = SKLabelNode(text: "IRON")
            nameLabel.fontSize = 8
            nameLabel.fontName = "AvenirNext-Bold"
            nameLabel.fontColor = .white
            nameLabel.verticalAlignmentMode = .center
            nameLabel.horizontalAlignmentMode = .center
            container.addChild(nameLabel)

        case 2: // Swarm Queen — orange pulsing orb with spawn sacs
            bar.fillColor = SKColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1)
            let body = SKShapeNode(circleOfRadius: 20)
            body.fillColor = SKColor(red: 0.8, green: 0.3, blue: 0.0, alpha: 1)
            body.strokeColor = SKColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1)
            body.lineWidth = 3
            container.addChild(body)
            // 4 spawn sacs at cardinal diagonals
            let sacAngles: [CGFloat] = [0, CGFloat.pi / 2, CGFloat.pi, 3 * CGFloat.pi / 2]
            for angle in sacAngles {
                let sac = SKShapeNode(circleOfRadius: 5)
                sac.fillColor = SKColor(red: 1.0, green: 0.7, blue: 0.0, alpha: 0.8)
                sac.strokeColor = SKColor.clear
                sac.position = CGPoint(x: cos(angle) * 18, y: sin(angle) * 18)
                container.addChild(sac)
            }
            let nameLabel = SKLabelNode(text: "QUEEN")
            nameLabel.fontSize = 7
            nameLabel.fontName = "AvenirNext-Bold"
            nameLabel.fontColor = .white
            nameLabel.verticalAlignmentMode = .center
            nameLabel.horizontalAlignmentMode = .center
            container.addChild(nameLabel)
            body.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.scale(to: 1.1, duration: 0.4),
                SKAction.scale(to: 0.9, duration: 0.4)
            ])))

        case 3: // Phase Runner — cyan fast angular body
            bar.fillColor = SKColor(red: 0.0, green: 0.9, blue: 0.9, alpha: 1)
            let body = SKShapeNode(rectOf: CGSize(width: 20, height: 30), cornerRadius: 8)
            body.fillColor = SKColor(red: 0.0, green: 0.6, blue: 0.8, alpha: 1)
            body.strokeColor = SKColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 1)
            body.lineWidth = 2
            container.addChild(body)
            // Speed lines
            for yOff: CGFloat in [-8, 0, 8] {
                let line = SKShapeNode(rectOf: CGSize(width: 14, height: 2))
                line.fillColor = SKColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 0.6)
                line.strokeColor = SKColor.clear
                line.position = CGPoint(x: 0, y: yOff)
                container.addChild(line)
            }
            let nameLabel = SKLabelNode(text: "PHASE")
            nameLabel.fontSize = 7
            nameLabel.fontName = "AvenirNext-Bold"
            nameLabel.fontColor = .white
            nameLabel.verticalAlignmentMode = .center
            nameLabel.horizontalAlignmentMode = .center
            container.addChild(nameLabel)

        case 4: // Void Titan — dark purple massive with rotating ring
            bar.fillColor = SKColor(red: 0.6, green: 0.0, blue: 0.8, alpha: 1)
            let outer = SKShapeNode(circleOfRadius: 26)
            outer.fillColor = SKColor(red: 0.1, green: 0.0, blue: 0.2, alpha: 1)
            outer.strokeColor = SKColor(red: 0.5, green: 0.0, blue: 0.8, alpha: 1)
            outer.lineWidth = 4
            container.addChild(outer)
            let inner = SKShapeNode(circleOfRadius: 14)
            inner.fillColor = SKColor(red: 0.3, green: 0.0, blue: 0.5, alpha: 1)
            inner.strokeColor = SKColor(red: 0.8, green: 0.3, blue: 1.0, alpha: 0.8)
            inner.lineWidth = 2
            container.addChild(inner)
            // Void swirl — rotating ring
            let swirl = SKShapeNode(circleOfRadius: 20)
            swirl.fillColor = SKColor.clear
            swirl.strokeColor = SKColor(red: 0.7, green: 0.2, blue: 1.0, alpha: 0.4)
            swirl.lineWidth = 2
            container.addChild(swirl)
            swirl.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 2.0)))
            let nameLabel = SKLabelNode(text: "VOID")
            nameLabel.fontSize = 8
            nameLabel.fontName = "AvenirNext-Bold"
            nameLabel.fontColor = SKColor(red: 0.8, green: 0.5, blue: 1.0, alpha: 1)
            nameLabel.verticalAlignmentMode = .center
            nameLabel.horizontalAlignmentMode = .center
            container.addChild(nameLabel)

        default: // 0: Rift Guardian — purple spiky standard boss, 30% armor
            bar.fillColor = SKColor(red: 0.6, green: 0.3, blue: 1.0, alpha: 1)
            // Rotating body sub-node
            let body = SKNode()
            container.addChild(body)
            let bodyShape = SKShapeNode(circleOfRadius: 22)
            bodyShape.fillColor = SKColor(red: 0.4, green: 0.0, blue: 0.6, alpha: 1)
            bodyShape.strokeColor = SKColor(red: 0.7, green: 0.4, blue: 1.0, alpha: 1)
            bodyShape.lineWidth = 3
            body.addChild(bodyShape)
            let core = SKShapeNode(circleOfRadius: 10)
            core.fillColor = SKColor(red: 0.8, green: 0.4, blue: 1.0, alpha: 1)
            core.strokeColor = SKColor.white
            core.lineWidth = 1
            body.addChild(core)
            // Diagonal spikes
            let spikeAngles: [CGFloat] = [CGFloat.pi / 4, 3 * CGFloat.pi / 4,
                                          5 * CGFloat.pi / 4, 7 * CGFloat.pi / 4]
            for angle in spikeAngles {
                let spike = SKShapeNode(rectOf: CGSize(width: 4, height: 14), cornerRadius: 2)
                spike.fillColor = SKColor(red: 0.7, green: 0.4, blue: 1.0, alpha: 0.9)
                spike.strokeColor = SKColor.clear
                spike.position = CGPoint(x: cos(angle) * 20, y: sin(angle) * 20)
                spike.zRotation = angle
                body.addChild(spike)
            }
            let nameLabel = SKLabelNode(text: "RIFT")
            nameLabel.fontSize = 8
            nameLabel.fontName = "AvenirNext-Bold"
            nameLabel.fontColor = .white
            nameLabel.verticalAlignmentMode = .center
            nameLabel.horizontalAlignmentMode = .center
            container.addChild(nameLabel)
            // Slow rotation
            body.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 3.0)))
            bodyShape.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.scale(to: 1.08, duration: 0.5),
                SKAction.scale(to: 0.94, duration: 0.5)
            ])))
        }

        return container
    }

    // MARK: - Shell Mode Damage Override (variant 1 — Iron Colossus)
    func applyDamage(_ rawAmount: CGFloat) {
        guard !shellActive else { return }   // no damage during shell
        let reducedDamage = rawAmount * (1.0 - armor)
        currentHP = max(0, currentHP - reducedDamage)
        refreshHealthBar()
        if isDead {
            spawnDeathParticles()
            node.removeFromParent()
        }
    }

    // MARK: - Boss Special Ability Tick
    func tickAbility(currentTime: TimeInterval, scene: GameScene) {
        let hpRatio = currentHP / maxHP
        switch bossVariant {
        case 0: // Rift Guardian — Rift Pulse: 60% attack speed debuff for 4s at 50% HP
            if !abilityTriggered && hpRatio <= 0.5 {
                abilityTriggered = true
                // Telegraph: flash all towers purple
                for tower in scene.activeTowers {
                    let flash = SKAction.sequence([
                        SKAction.colorize(with: SKColor(red: 0.55, green: 0.0, blue: 1.0, alpha: 1), colorBlendFactor: 0.8, duration: 0.1),
                        SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.1),
                        SKAction.colorize(with: SKColor(red: 0.55, green: 0.0, blue: 1.0, alpha: 1), colorBlendFactor: 0.8, duration: 0.1),
                        SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.1)
                    ])
                    tower.node.run(flash)
                }
                scene.triggerRiftPulse(duration: 4.0)
            }
        case 1: // Iron Colossus — Shell Mode: 2s immunity every 8s cycle after 50% HP
            if !abilityTriggered && hpRatio <= 0.5 {
                abilityTriggered = true
                shellTimer = currentTime
            }
            if abilityTriggered {
                let elapsed = currentTime - shellTimer
                let cyclePos = elapsed.truncatingRemainder(dividingBy: 8.0)
                let wasShellActive = shellActive
                shellActive = cyclePos < 2.0
                // Update visual when shell state changes
                if shellActive != wasShellActive {
                    if let shape = node.children.first(where: { $0 is SKShapeNode }) as? SKShapeNode {
                        shape.alpha = shellActive ? 0.5 : 1.0
                    }
                    node.alpha = shellActive ? 0.5 : 1.0
                }
            }
        case 2: // Swarm Queen — Brood Burst: spawn 6 Swarms at 50% HP
            if !abilityTriggered && hpRatio <= 0.5 {
                abilityTriggered = true
                // Telegraph: pulse egg sacs
                let sacPulse = SKAction.repeat(SKAction.sequence([
                    SKAction.scale(to: 1.4, duration: 0.1),
                    SKAction.scale(to: 1.0, duration: 0.1)
                ]), count: 3)
                node.run(SKAction.sequence([
                    sacPulse,
                    SKAction.run { [weak self] in
                        guard let self = self else { return }
                        scene.spawnBroodBurst(at: self.pathProgress, count: 6)
                    }
                ]))
            }
        case 3: // Phase Runner — Overdrive: 2x speed + frost immunity for 5s at 50% HP
            if !abilityTriggered && hpRatio <= 0.5 {
                abilityTriggered = true
                currentSpeed = baseSpeed * 2.0
                scene.scheduleReset(for: self, after: 5.0)
            }
        case 4: // Void Titan — Gravity Well every 10s
            if gravityWellTimer == 0 { gravityWellTimer = currentTime }
            if currentTime - gravityWellTimer >= 10.0 {
                gravityWellTimer = currentTime
                scene.triggerGravityWell(duration: 2.0)
            }
        default: break
        }
    }
}
