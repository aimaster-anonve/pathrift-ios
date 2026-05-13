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
        // Body
        let body = SKShapeNode(circleOfRadius: 12)
        body.fillColor = SKColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1)
        body.strokeColor = SKColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1)
        body.lineWidth = 2
        body.name = "core"
        node.addChild(body)

        // Shield ring
        let shield = SKShapeNode(circleOfRadius: 17)
        shield.fillColor = SKColor(red: 0.5, green: 0.8, blue: 1.0, alpha: 0.2)
        shield.strokeColor = SKColor(red: 0.5, green: 0.9, blue: 1.0, alpha: 0.9)
        shield.lineWidth = 3
        shield.name = "shieldRing"
        node.addChild(shield)
        shieldNode = shield

        // Shield pulse animation
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
