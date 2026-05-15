import Foundation
import CoreGraphics
import SpriteKit

final class ShieldEnemy: EnemyNode {
    let type: EnemyType = .shield
    let maxHP: CGFloat
    var currentHP: CGFloat
    let baseSpeed: CGFloat = 85
    var currentSpeed: CGFloat
    let armor: CGFloat = 0.0
    let goldReward: Int = 12
    var pathProgress: CGFloat = 0
    var hasReachedEnd: Bool = false
    var slowTimer: TimeInterval = 0
    var pathLayer: PathLayer = .ground
    let node: SKNode

    private var shieldHP: CGFloat = 80
    private var shieldBroken: Bool = false
    private var shieldNode: SKShapeNode?

    init(hpMultiplier: CGFloat = 1.0) {
        let hp = 120 * hpMultiplier
        self.maxHP = hp
        self.currentHP = hp
        self.currentSpeed = 85
        let container = SKNode()
        container.zPosition = 4
        self.node = container
        self.node.position = PathSystem.waypoints.first ?? .zero
        setupNode()
    }

    // Override applyDamage to handle shield absorption
    func applyDamage(_ rawAmount: CGFloat) {
        if !shieldBroken && shieldHP > 0 {
            if rawAmount >= shieldHP {
                let overflow = rawAmount - shieldHP
                shieldHP = 0
                breakShield()
                if overflow > 0 {
                    currentHP = max(0, currentHP - overflow)
                }
            } else {
                shieldHP -= rawAmount
                shieldNode?.run(SKAction.sequence([
                    SKAction.colorize(with: .white, colorBlendFactor: 1, duration: 0.05),
                    SKAction.colorize(withColorBlendFactor: 0, duration: 0.1)
                ]))
            }
        } else {
            currentHP = max(0, currentHP - rawAmount)
        }
        refreshHealthBar()
        if isDead {
            spawnDeathParticles()
            node.removeFromParent()
        }
    }

    private func breakShield() {
        shieldBroken = true
        shieldNode?.run(SKAction.sequence([
            SKAction.scale(to: 2.0, duration: 0.1),
            SKAction.fadeOut(withDuration: 0.15),
            SKAction.removeFromParent()
        ]))
        shieldNode = nil
        // Reveal weak core — turn it red/orange
        if let core = node.childNode(withName: "core") as? SKShapeNode {
            core.fillColor = SKColor(red: 0.9, green: 0.3, blue: 0.1, alpha: 1)
        }
    }

    private func setupNode() {
        // Shadow — 13×4pt (0.70× 18×6)
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 13, height: 4))
        shadow.fillColor = SKColor(red: 0, green: 0, blue: 0, alpha: 0.30)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -10)
        node.addChild(shadow)

        // Circle body — radius 6 (0.70× 9)
        let body = SKShapeNode(circleOfRadius: 6)
        body.fillColor = SKColor(red: 0.04, green: 0.24, blue: 0.12, alpha: 1.0)
        body.strokeColor = SKColor(red: 0.20, green: 0.85, blue: 0.40, alpha: 1.0)
        body.lineWidth = 1.0
        body.name = "core"
        node.addChild(body)

        // Shield aura — radius 10 (0.70× 14)
        let shield = SKShapeNode(circleOfRadius: 10)
        shield.fillColor = SKColor(red: 0.15, green: 0.90, blue: 0.40, alpha: 0.15)
        shield.strokeColor = SKColor(red: 0.20, green: 0.85, blue: 0.40, alpha: 0.50)
        shield.lineWidth = 0.75
        shield.name = "shieldRing"
        node.addChild(shield)
        shieldNode = shield

        let pulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.6),
            SKAction.fadeAlpha(to: 1.0, duration: 0.6)
        ]))
        shield.run(pulse)

        let (bg, bar) = ShieldEnemy.makeHealthBarNodes()
        node.addChild(bg)
        node.addChild(bar)
    }
}
