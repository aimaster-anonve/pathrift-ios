import Foundation
import CoreGraphics
import SpriteKit

final class NovaTower: Tower {
    let type: TowerType = .nova
    var position: CGPoint
    var slotId: Int
    var lastFiredTime: TimeInterval = 0
    let node: SKNode
    var level: Int = 1
    var totalInvested: Int

    /// Called by GameScene to apply AoE damage to all enemies within nova radius.
    var novaDamageCallback: ((CGPoint, CGFloat, CGFloat) -> Void)?

    init(position: CGPoint, slotId: Int) {
        self.position = position
        self.slotId = slotId
        self.totalInvested = 500
        self.node = NovaTower.makeNode(at: position)
    }

    static func makeNode(at position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position

        // Base
        let base = SKShapeNode(rectOf: CGSize(width: 40, height: 8), cornerRadius: 3)
        base.fillColor = SKColor(red: 0.18, green: 0.16, blue: 0.06, alpha: 1)
        base.strokeColor = SKColor(red: 1.0, green: 0.95, blue: 0.5, alpha: 0.6)
        base.lineWidth = 1.5
        base.position = CGPoint(x: 0, y: -12)
        container.addChild(base)

        // Body — wide stellar shape
        let body = SKShapeNode(circleOfRadius: 15)
        body.fillColor = SKColor(red: 0.15, green: 0.13, blue: 0.04, alpha: 1)
        body.strokeColor = SKColor(red: 1.0, green: 0.95, blue: 0.5, alpha: 1)
        body.lineWidth = 2.5
        container.addChild(body)

        // Stellar core
        let core = SKShapeNode(circleOfRadius: 7)
        core.fillColor = SKColor(red: 1.0, green: 0.95, blue: 0.5, alpha: 1)
        core.strokeColor = SKColor.white
        core.lineWidth = 1
        container.addChild(core)

        // Star rays (8 directions)
        let rayAngles: [CGFloat] = [
            0,
            CGFloat.pi / 4,
            CGFloat.pi / 2,
            3 * CGFloat.pi / 4,
            CGFloat.pi,
            5 * CGFloat.pi / 4,
            3 * CGFloat.pi / 2,
            7 * CGFloat.pi / 4
        ]
        for angle in rayAngles {
            let ray = SKShapeNode(rectOf: CGSize(width: 2, height: 10), cornerRadius: 1)
            ray.fillColor = SKColor(red: 1.0, green: 0.95, blue: 0.5, alpha: 0.7)
            ray.strokeColor = SKColor.clear
            ray.position = CGPoint(x: cos(angle) * 13, y: sin(angle) * 13)
            ray.zRotation = angle
            container.addChild(ray)
        }

        // Outer corona
        let corona = SKShapeNode(circleOfRadius: 20)
        corona.fillColor = SKColor.clear
        corona.strokeColor = SKColor(red: 1.0, green: 0.95, blue: 0.5, alpha: 0.2)
        corona.lineWidth = 3
        container.addChild(corona)

        // Slow pulse (charging up)
        let slowPulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.1, duration: 1.2),
            SKAction.fadeAlpha(to: 0.6, duration: 1.2)
        ]))
        corona.run(slowPulse)

        // Core rotation
        let rotate = SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 3.0))
        core.run(rotate)

        return container
    }

    func buildNode() -> SKNode {
        NovaTower.makeNode(at: position)
    }

    func fire(at enemy: EnemyNode, scene: SKScene, currentTime: TimeInterval) {
        lastFiredTime = currentTime

        let novaRadius = type.blastRadius ?? 160
        let damage = scaledDamage() * type.damageMultiplier(against: enemy.type)
        let targetPos = enemy.node.position

        // Charging projectile
        let orb = SKShapeNode(circleOfRadius: 12)
        orb.fillColor = type.projectileColor.withAlphaComponent(0.7)
        orb.strokeColor = SKColor.white
        orb.lineWidth = 2
        orb.position = position
        orb.zPosition = 5
        scene.addChild(orb)

        let novaCallback = novaDamageCallback
        let move = SKAction.move(to: targetPos, duration: 0.35)
        let burst = SKAction.run { [weak scene] in
            orb.removeFromParent()
            guard let scene = scene else { return }

            // Nova burst visual
            let burstRing = SKShapeNode(circleOfRadius: novaRadius)
            burstRing.fillColor = SKColor(red: 1.0, green: 0.95, blue: 0.5, alpha: 0.2)
            burstRing.strokeColor = SKColor(red: 1.0, green: 0.95, blue: 0.5, alpha: 0.9)
            burstRing.lineWidth = 3
            burstRing.position = targetPos
            burstRing.zPosition = 5
            scene.addChild(burstRing)

            // Inner bright flash
            let innerFlash = SKShapeNode(circleOfRadius: 30)
            innerFlash.fillColor = SKColor.white.withAlphaComponent(0.8)
            innerFlash.strokeColor = SKColor.clear
            innerFlash.position = targetPos
            innerFlash.zPosition = 6
            scene.addChild(innerFlash)

            burstRing.run(SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 1.3, duration: 0.3),
                    SKAction.fadeOut(withDuration: 0.3)
                ]),
                SKAction.removeFromParent()
            ]))
            innerFlash.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.removeFromParent()
            ]))

            novaCallback?(targetPos, novaRadius, damage)
        }

        orb.run(SKAction.sequence([move, burst]))

        // Charging glow on tower
        let charge = SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.15)
        ])
        node.run(charge)
    }
}
