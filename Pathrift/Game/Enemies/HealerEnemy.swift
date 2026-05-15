import Foundation
import CoreGraphics
import SpriteKit

final class HealerEnemy: EnemyNode {
    let type: EnemyType = .healer
    let maxHP: CGFloat
    var currentHP: CGFloat
    let baseSpeed: CGFloat = 35
    var currentSpeed: CGFloat
    let armor: CGFloat = 0.0
    let goldReward: Int = EconomyConstants.EnemyGoldReward.healer
    var pathProgress: CGFloat = 0
    var hasReachedEnd: Bool = false
    var slowTimer: TimeInterval = 0
    var pathLayer: PathLayer = .ground
    let node: SKNode

    private var lastHealTime: TimeInterval = 0
    private let healInterval: TimeInterval = 2.5
    private let healAmount: CGFloat = 18
    private let healRadius: CGFloat = 80

    init(hpMultiplier: CGFloat = 1.0) {
        let hp = 140 * hpMultiplier
        self.maxHP = hp
        self.currentHP = hp
        self.currentSpeed = 35
        self.node = HealerEnemy.makeNode()
        self.node.position = PathSystem.waypoints.first ?? .zero
    }

    private static func makeNode() -> SKNode {
        let container = SKNode()
        container.zPosition = 4

        // Outer aura ring — radius 11 (0.70× 16)
        let auraRing = SKShapeNode(circleOfRadius: 11)
        auraRing.fillColor = SKColor(red: 0.18, green: 0.80, blue: 0.44, alpha: 0.12)
        auraRing.strokeColor = SKColor(red: 0.18, green: 0.80, blue: 0.44, alpha: 0.35)
        auraRing.lineWidth = 1.0
        auraRing.name = "auraRing"
        container.addChild(auraRing)

        // Outer ring — radius 8 (0.70× 11)
        let outerRing = SKShapeNode(circleOfRadius: 8)
        outerRing.fillColor = SKColor(red: 0.18, green: 0.80, blue: 0.44, alpha: 0.30)
        outerRing.strokeColor = SKColor(red: 0.67, green: 1.00, blue: 0.82, alpha: 0.90)
        outerRing.lineWidth = 1.5
        container.addChild(outerRing)

        // Inner circle — radius 4 (0.70× 6)
        let innerCircle = SKShapeNode(circleOfRadius: 4)
        innerCircle.fillColor = SKColor(red: 0.10, green: 0.55, blue: 0.30, alpha: 0.70)
        innerCircle.strokeColor = SKColor(red: 0.18, green: 0.80, blue: 0.44, alpha: 0.60)
        innerCircle.lineWidth = 0.75
        container.addChild(innerCircle)

        // Cross symbol — 0.70× sizes
        let vBar = SKShapeNode(rectOf: CGSize(width: 1.5, height: 6))
        vBar.fillColor = SKColor(red: 0.67, green: 1.00, blue: 0.82, alpha: 0.90)
        vBar.strokeColor = SKColor.clear
        container.addChild(vBar)

        let hBar = SKShapeNode(rectOf: CGSize(width: 6, height: 1.5))
        hBar.fillColor = SKColor(red: 0.67, green: 1.00, blue: 0.82, alpha: 0.90)
        hBar.strokeColor = SKColor.clear
        container.addChild(hBar)

        // Health bar
        let (bg, bar) = HealerEnemy.makeHealthBarNodes()
        container.addChild(bg)
        container.addChild(bar)

        // Pulsing aura animation
        auraRing.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.25, duration: 1.2),
                SKAction.fadeAlpha(to: 0.06, duration: 1.2)
            ]),
            SKAction.group([
                SKAction.scale(to: 1.0, duration: 1.2),
                SKAction.fadeAlpha(to: 0.35, duration: 1.2)
            ])
        ])))

        return container
    }

    /// Called each frame — heals nearby living enemies every 2.5s
    func tickHeal(currentTime: TimeInterval, allEnemies: [any EnemyNode]) {
        guard isAlive else { return }
        guard currentTime - lastHealTime >= healInterval else { return }
        lastHealTime = currentTime

        let myPos = node.position
        for enemy in allEnemies {
            guard enemy !== self as any EnemyNode else { continue }
            guard enemy.isAlive else { continue }
            let dx = enemy.node.position.x - myPos.x
            let dy = enemy.node.position.y - myPos.y
            if sqrt(dx * dx + dy * dy) <= healRadius {
                enemy.currentHP = min(enemy.maxHP, enemy.currentHP + healAmount)
                enemy.refreshHealthBar()
                // Small green flash on healed enemy
                let healFlash = SKAction.sequence([
                    SKAction.colorize(with: SKColor(red: 0.18, green: 0.80, blue: 0.44, alpha: 1), colorBlendFactor: 0.6, duration: 0.1),
                    SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.2)
                ])
                enemy.node.run(healFlash)
            }
        }

        // Pulse aura on heal
        if let auraRing = node.childNode(withName: "auraRing") as? SKShapeNode {
            auraRing.run(SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 1.8, duration: 0.25),
                    SKAction.fadeAlpha(to: 0.8, duration: 0.25)
                ]),
                SKAction.group([
                    SKAction.scale(to: 1.0, duration: 0.25),
                    SKAction.fadeAlpha(to: 0.35, duration: 0.25)
                ])
            ]))
        }
    }
}
