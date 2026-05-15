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

    // Override refreshHealthBar for the boss health bar (40pt wide, 4pt tall)
    func refreshHealthBar() {
        guard let bar = node.childNode(withName: "healthBar") as? SKShapeNode else { return }
        let ratio = max(0, currentHP / maxHP)
        let totalWidth: CGFloat = 40
        let filledWidth = totalWidth * ratio

        let path = CGMutablePath()
        path.addRect(CGRect(x: -totalWidth / 2, y: 0, width: filledWidth, height: 4))
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

        // Boss health bar (40pt wide × 4pt tall — 0.70× 56×5)
        let bgPath = CGMutablePath()
        bgPath.addRect(CGRect(x: -20, y: 0, width: 40, height: 4))
        let bg = SKShapeNode(path: bgPath)
        bg.fillColor = SKColor.darkGray
        bg.strokeColor = SKColor.clear
        bg.name = "healthBarBg"
        bg.position = CGPoint(x: 0, y: 27)
        container.addChild(bg)

        let barPath = CGMutablePath()
        barPath.addRect(CGRect(x: -20, y: 0, width: 40, height: 4))
        let bar = SKShapeNode(path: barPath)
        bar.strokeColor = SKColor.clear
        bar.name = "healthBar"
        bar.position = CGPoint(x: 0, y: 27)
        container.addChild(bar)

        // Boss number label
        let bossNum = waveNumber / 10
        let numLabel = SKLabelNode(text: "#\(bossNum)")
        numLabel.fontSize = 7
        numLabel.fontName = "AvenirNext-Bold"
        numLabel.fontColor = SKColor(white: 1, alpha: 0.7)
        numLabel.verticalAlignmentMode = .center
        numLabel.horizontalAlignmentMode = .center
        numLabel.position = CGPoint(x: 0, y: 35)
        container.addChild(numLabel)

        // Variant-specific visuals — all 0.70× scaled from originals
        switch variant {
        case 1: // Iron Colossus — grey armored square (0.70× 38→27, 32→22, 12→8)
            bar.fillColor = SKColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1)
            let hull = SKShapeNode(rectOf: CGSize(width: 27, height: 27), cornerRadius: 3.5)
            hull.fillColor = SKColor(red: 0.4, green: 0.4, blue: 0.45, alpha: 1)
            hull.strokeColor = SKColor(red: 0.7, green: 0.7, blue: 0.8, alpha: 1)
            hull.lineWidth = 2
            container.addChild(hull)
            let plates = SKShapeNode(rectOf: CGSize(width: 22, height: 8), cornerRadius: 1.5)
            plates.fillColor = SKColor(red: 0.5, green: 0.5, blue: 0.55, alpha: 1)
            plates.strokeColor = SKColor.clear
            container.addChild(plates)
            let nameLabel = SKLabelNode(text: "IRON")
            nameLabel.fontSize = 7
            nameLabel.fontName = "AvenirNext-Bold"
            nameLabel.fontColor = .white
            nameLabel.verticalAlignmentMode = .center
            nameLabel.horizontalAlignmentMode = .center
            container.addChild(nameLabel)

        case 2: // Swarm Queen — orange pulsing orb (0.70× 20→14, sac 5→3.5, orbit 18→13)
            bar.fillColor = SKColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1)
            let body = SKShapeNode(circleOfRadius: 14)
            body.fillColor = SKColor(red: 0.8, green: 0.3, blue: 0.0, alpha: 1)
            body.strokeColor = SKColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1)
            body.lineWidth = 2
            container.addChild(body)
            let sacAngles: [CGFloat] = [0, CGFloat.pi / 2, CGFloat.pi, 3 * CGFloat.pi / 2]
            for angle in sacAngles {
                let sac = SKShapeNode(circleOfRadius: 3.5)
                sac.fillColor = SKColor(red: 1.0, green: 0.7, blue: 0.0, alpha: 0.8)
                sac.strokeColor = SKColor.clear
                sac.position = CGPoint(x: cos(angle) * 13, y: sin(angle) * 13)
                container.addChild(sac)
            }
            let nameLabel = SKLabelNode(text: "QUEEN")
            nameLabel.fontSize = 6
            nameLabel.fontName = "AvenirNext-Bold"
            nameLabel.fontColor = .white
            nameLabel.verticalAlignmentMode = .center
            nameLabel.horizontalAlignmentMode = .center
            container.addChild(nameLabel)
            body.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.scale(to: 1.1, duration: 0.4),
                SKAction.scale(to: 0.9, duration: 0.4)
            ])))

        case 3: // Phase Runner — cyan angular body (0.70× 20×30→14×21)
            bar.fillColor = SKColor(red: 0.0, green: 0.9, blue: 0.9, alpha: 1)
            let body = SKShapeNode(rectOf: CGSize(width: 14, height: 21), cornerRadius: 5.5)
            body.fillColor = SKColor(red: 0.0, green: 0.6, blue: 0.8, alpha: 1)
            body.strokeColor = SKColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 1)
            body.lineWidth = 1.5
            container.addChild(body)
            for yOff: CGFloat in [-5.5, 0, 5.5] {
                let line = SKShapeNode(rectOf: CGSize(width: 10, height: 1.5))
                line.fillColor = SKColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 0.6)
                line.strokeColor = SKColor.clear
                line.position = CGPoint(x: 0, y: yOff)
                container.addChild(line)
            }
            let nameLabel = SKLabelNode(text: "PHASE")
            nameLabel.fontSize = 6
            nameLabel.fontName = "AvenirNext-Bold"
            nameLabel.fontColor = .white
            nameLabel.verticalAlignmentMode = .center
            nameLabel.horizontalAlignmentMode = .center
            container.addChild(nameLabel)

        case 4: // Void Titan — dark purple (0.70× outer 26→18, inner 14→10, swirl 20→14)
            bar.fillColor = SKColor(red: 0.6, green: 0.0, blue: 0.8, alpha: 1)
            let outer = SKShapeNode(circleOfRadius: 18)
            outer.fillColor = SKColor(red: 0.1, green: 0.0, blue: 0.2, alpha: 1)
            outer.strokeColor = SKColor(red: 0.5, green: 0.0, blue: 0.8, alpha: 1)
            outer.lineWidth = 3
            container.addChild(outer)
            let inner = SKShapeNode(circleOfRadius: 10)
            inner.fillColor = SKColor(red: 0.3, green: 0.0, blue: 0.5, alpha: 1)
            inner.strokeColor = SKColor(red: 0.8, green: 0.3, blue: 1.0, alpha: 0.8)
            inner.lineWidth = 1.5
            container.addChild(inner)
            let swirl = SKShapeNode(circleOfRadius: 14)
            swirl.fillColor = SKColor.clear
            swirl.strokeColor = SKColor(red: 0.7, green: 0.2, blue: 1.0, alpha: 0.4)
            swirl.lineWidth = 1.5
            container.addChild(swirl)
            swirl.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 2.0)))
            let nameLabel = SKLabelNode(text: "VOID")
            nameLabel.fontSize = 7
            nameLabel.fontName = "AvenirNext-Bold"
            nameLabel.fontColor = SKColor(red: 0.8, green: 0.5, blue: 1.0, alpha: 1)
            nameLabel.verticalAlignmentMode = .center
            nameLabel.horizontalAlignmentMode = .center
            container.addChild(nameLabel)

        default: // 0: Rift Guardian — purple spiky (0.70× body 22→15, core 10→7, spike offset 20→14)
            bar.fillColor = SKColor(red: 0.6, green: 0.3, blue: 1.0, alpha: 1)
            let body = SKNode()
            container.addChild(body)
            let bodyShape = SKShapeNode(circleOfRadius: 15)
            bodyShape.fillColor = SKColor(red: 0.4, green: 0.0, blue: 0.6, alpha: 1)
            bodyShape.strokeColor = SKColor(red: 0.7, green: 0.4, blue: 1.0, alpha: 1)
            bodyShape.lineWidth = 2
            body.addChild(bodyShape)
            let core = SKShapeNode(circleOfRadius: 7)
            core.fillColor = SKColor(red: 0.8, green: 0.4, blue: 1.0, alpha: 1)
            core.strokeColor = SKColor.white
            core.lineWidth = 0.75
            body.addChild(core)
            let spikeAngles: [CGFloat] = [CGFloat.pi / 4, 3 * CGFloat.pi / 4,
                                          5 * CGFloat.pi / 4, 7 * CGFloat.pi / 4]
            for angle in spikeAngles {
                let spike = SKShapeNode(rectOf: CGSize(width: 3, height: 10), cornerRadius: 1.5)
                spike.fillColor = SKColor(red: 0.7, green: 0.4, blue: 1.0, alpha: 0.9)
                spike.strokeColor = SKColor.clear
                spike.position = CGPoint(x: cos(angle) * 14, y: sin(angle) * 14)
                spike.zRotation = angle
                body.addChild(spike)
            }
            let nameLabel = SKLabelNode(text: "RIFT")
            nameLabel.fontSize = 7
            nameLabel.fontName = "AvenirNext-Bold"
            nameLabel.fontColor = .white
            nameLabel.verticalAlignmentMode = .center
            nameLabel.horizontalAlignmentMode = .center
            container.addChild(nameLabel)
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
