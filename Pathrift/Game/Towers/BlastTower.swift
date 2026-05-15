import Foundation
import CoreGraphics
import SpriteKit

final class BlastTower: Tower {
    let type: TowerType = .blast
    var position: CGPoint
    var slotId: Int
    var lastFiredTime: TimeInterval = 0
    let node: SKNode
    var level: Int = 1
    var totalInvested: Int

    /// Called by GameScene to apply AoE damage to nearby enemies when shell impacts.
    var blastDamageCallback: ((CGPoint, CGFloat, CGFloat) -> Void)?

    init(position: CGPoint, slotId: Int) {
        self.position = position
        self.slotId = slotId
        self.totalInvested = EconomyConstants.TowerCost.blast
        self.node = BlastTower.makeNode(at: position)
    }

    static func makeNode(at position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position

        // Floor shadow
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 28, height: 10))
        shadow.fillColor = SKColor(red: 0, green: 0, blue: 0, alpha: 0.35)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -14)
        container.addChild(shadow)

        // Circle body
        let body = SKShapeNode(circleOfRadius: 14)
        body.fillColor = SKColor(red: 0.20, green: 0.08, blue: 0.00, alpha: 1.0)
        body.strokeColor = SKColor(red: 1.00, green: 0.45, blue: 0.00, alpha: 1.0)
        body.lineWidth = 2.0
        container.addChild(body)

        // 3 exhaust pipe stubs at 120° intervals (excluding up/barrel direction)
        // Barrel points up (90°), so exhaust at 210°, 330°, and 90° excluded — use 210°, 330°, 30° (offset -30 from barrel)
        let exhaustAngles: [CGFloat] = [CGFloat.pi * 7 / 6, CGFloat.pi * 11 / 6, CGFloat.pi / 6]
        for angle in exhaustAngles {
            let px = cos(angle) * 14
            let py = sin(angle) * 14
            let pipe = SKShapeNode(rectOf: CGSize(width: 5, height: 7), cornerRadius: 1)
            pipe.fillColor = SKColor(red: 0.15, green: 0.06, blue: 0.00, alpha: 1.0)
            pipe.strokeColor = SKColor(red: 1.00, green: 0.45, blue: 0.00, alpha: 1.0)
            pipe.lineWidth = 1.0
            pipe.position = CGPoint(x: px, y: py)
            pipe.zRotation = angle
            container.addChild(pipe)
            // Pulse outward animation
            pipe.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.moveBy(x: cos(angle) * 0.5, y: sin(angle) * 0.5, duration: 0.6),
                SKAction.moveBy(x: -cos(angle) * 0.5, y: -sin(angle) * 0.5, duration: 0.6)
            ])))
        }

        // Barrel (flared tip trapezoid approximated as wider rect + tip)
        let barrel = SKShapeNode(rectOf: CGSize(width: 6, height: 12), cornerRadius: 1)
        barrel.fillColor = SKColor(red: 1.00, green: 0.45, blue: 0.00, alpha: 1.0)
        barrel.strokeColor = .clear
        barrel.position = CGPoint(x: 0, y: 17)
        container.addChild(barrel)

        // Flared tip
        let tip = SKShapeNode(rectOf: CGSize(width: 10, height: 3))
        tip.fillColor = SKColor(red: 1.00, green: 0.45, blue: 0.00, alpha: 0.80)
        tip.strokeColor = .clear
        tip.position = CGPoint(x: 0, y: 23)
        container.addChild(tip)

        return container
    }

    func buildNode() -> SKNode {
        BlastTower.makeNode(at: position)
    }

    func fire(at enemy: EnemyNode, scene: SKScene, currentTime: TimeInterval) {
        lastFiredTime = currentTime

        let shell = SKShapeNode(circleOfRadius: 8)
        shell.fillColor = type.projectileColor
        shell.strokeColor = SKColor.white
        shell.lineWidth = 1
        shell.position = position
        shell.zPosition = 5
        scene.addChild(shell)

        let targetPos = enemy.node.position
        let blastRadius = type.blastRadius ?? 96
        let damage = scaledDamage() * type.damageMultiplier(against: enemy.type)

        let move = SKAction.move(to: targetPos, duration: 0.25)
        let blastCallback = blastDamageCallback
        let explode = SKAction.run { [weak scene] in
            shell.removeFromParent()
            guard let scene = scene else { return }

            let explosion = SKShapeNode(circleOfRadius: blastRadius)
            explosion.fillColor = SKColor.orange.withAlphaComponent(0.4)
            explosion.strokeColor = SKColor.orange
            explosion.lineWidth = 2
            explosion.position = targetPos
            explosion.zPosition = 5
            scene.addChild(explosion)

            let expand = SKAction.scale(to: 1.5, duration: 0.2)
            let fade = SKAction.fadeOut(withDuration: 0.2)
            explosion.run(SKAction.sequence([
                SKAction.group([expand, fade]),
                SKAction.removeFromParent()
            ]))

            blastCallback?(targetPos, blastRadius, damage)
        }

        shell.run(SKAction.sequence([move, explode]))

        let shakeX = SKAction.sequence([
            SKAction.moveBy(x: 3, y: 0, duration: 0.05),
            SKAction.moveBy(x: -6, y: 0, duration: 0.05),
            SKAction.moveBy(x: 3, y: 0, duration: 0.05)
        ])
        node.run(shakeX)
    }
}
