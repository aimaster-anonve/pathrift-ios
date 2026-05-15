import Foundation
import CoreGraphics
import SpriteKit

final class PhantomEnemy: EnemyNode {
    let type: EnemyType = .phantom
    let maxHP: CGFloat
    var currentHP: CGFloat
    let baseSpeed: CGFloat = 60
    var currentSpeed: CGFloat
    let armor: CGFloat = 0.0
    let goldReward: Int = EconomyConstants.EnemyGoldReward.phantom
    var pathProgress: CGFloat = 0
    var hasReachedEnd: Bool = false
    var slowTimer: TimeInterval = 0
    var pathLayer: PathLayer = .ground
    let node: SKNode

    /// When true, single-target projectile hits can be dodged (40% chance).
    /// False for AoE damage (Blast, Inferno, Nova, Tesla, Artillery area damage).
    var isDodgeable: Bool = true

    static let dodgeChance: Double = 0.40

    init(hpMultiplier: CGFloat = 1.0) {
        let hp = 90 * hpMultiplier
        self.maxHP = hp
        self.currentHP = hp
        self.currentSpeed = 60
        self.node = PhantomEnemy.makeNode()
        self.node.position = PathSystem.waypoints.first ?? .zero
    }

    /// AoE damage always hits — no dodge (Blast, Nova, Artillery bypass).
    func applyAoeDamage(_ rawAmount: CGFloat) {
        currentHP = max(0, currentHP - rawAmount)
        refreshHealthBar()
        if isDead {
            spawnDeathParticles()
            node.removeFromParent()
        }
    }

    /// Override applyDamage: 40% dodge chance vs single-target projectiles.
    func applyDamage(_ rawAmount: CGFloat) {
        if isDodgeable && Double.random(in: 0...1) < PhantomEnemy.dodgeChance {
            // Dodge! Visual feedback
            let dodgeFlash = SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 1.3, duration: 0.07),
                    SKAction.colorize(with: SKColor.white, colorBlendFactor: 0.9, duration: 0.07)
                ]),
                SKAction.group([
                    SKAction.scale(to: 1.0, duration: 0.08),
                    SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.08)
                ])
            ])
            node.run(dodgeFlash)
            return
        }
        // No armor — direct damage
        currentHP = max(0, currentHP - rawAmount)
        refreshHealthBar()
        if isDead {
            spawnDeathParticles()
            node.removeFromParent()
        }
    }

    private static func makeNode() -> SKNode {
        let container = SKNode()
        container.zPosition = 4
        container.alpha = 0.75

        // 5-point star body — outerR 7 (0.70× 10), innerR 3 (0.70× 4.5)
        let starPath = CGMutablePath()
        let outerR: CGFloat = 7
        let innerR: CGFloat = 3
        for i in 0..<10 {
            let angle = CGFloat(i) * (.pi / 5) - (.pi / 2)
            let r: CGFloat = i.isMultiple(of: 2) ? outerR : innerR
            let pt = CGPoint(x: cos(angle) * r, y: sin(angle) * r)
            i == 0 ? starPath.move(to: pt) : starPath.addLine(to: pt)
        }
        starPath.closeSubpath()

        let body = SKShapeNode(path: starPath)
        body.fillColor = SKColor(red: 0.55, green: 0.00, blue: 1.00, alpha: 0.75)
        body.strokeColor = SKColor(red: 0.80, green: 0.40, blue: 1.00, alpha: 0.90)
        body.lineWidth = 1.0
        container.addChild(body)

        // Inner glow core — radius 3 (0.70× 4)
        let core = SKShapeNode(circleOfRadius: 3)
        core.fillColor = SKColor(red: 0.70, green: 0.30, blue: 1.00, alpha: 0.50)
        core.strokeColor = SKColor.clear
        container.addChild(core)

        // Health bar
        let (bg, bar) = PhantomEnemy.makeHealthBarNodes()
        container.addChild(bg)
        container.addChild(bar)

        // Phase animation: alpha breathes
        container.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.50, duration: 1.0),
            SKAction.fadeAlpha(to: 0.90, duration: 1.0)
        ])))

        // Subtle rotation (ghostly spin)
        body.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 6.0)))

        return container
    }
}
