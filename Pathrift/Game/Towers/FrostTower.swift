import Foundation
import CoreGraphics
import SpriteKit

final class FrostTower: Tower {
    let type: TowerType = .frost
    var position: CGPoint
    var slotId: Int
    var lastFiredTime: TimeInterval = 0
    let node: SKNode
    var level: Int = 1
    var totalInvested: Int

    init(position: CGPoint, slotId: Int) {
        self.position = position
        self.slotId = slotId
        self.totalInvested = EconomyConstants.TowerCost.frost
        self.node = FrostTower.makeNode(at: position)
    }

    static func makeNode(at position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position

        // Base
        let base = SKShapeNode(rectOf: CGSize(width: 36, height: 8), cornerRadius: 3)
        base.fillColor = SKColor(red: 0.06, green: 0.10, blue: 0.20, alpha: 1)
        base.strokeColor = SKColor(red: 0.55, green: 0.78, blue: 1.0, alpha: 0.6)
        base.lineWidth = 1.5
        base.position = CGPoint(x: 0, y: -12)
        container.addChild(base)

        // Circular body
        let body = SKShapeNode(circleOfRadius: 13)
        body.fillColor = SKColor(red: 0.06, green: 0.12, blue: 0.28, alpha: 1)
        body.strokeColor = SKColor(red: 0.55, green: 0.85, blue: 1.0, alpha: 1)
        body.lineWidth = 2
        container.addChild(body)

        // Ice crystal center
        let crystal = SKShapeNode(circleOfRadius: 5)
        crystal.fillColor = SKColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 1)
        crystal.strokeColor = SKColor.white
        crystal.lineWidth = 1
        container.addChild(crystal)

        // Crystal spikes (4 directions)
        for angle in [CGFloat(0.0), CGFloat.pi / 2, CGFloat.pi, 3 * CGFloat.pi / 2] {
            let spike = SKShapeNode(rectOf: CGSize(width: 3, height: 12), cornerRadius: 1)
            spike.fillColor = SKColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 0.9)
            spike.strokeColor = SKColor.clear
            spike.position = CGPoint(x: cos(angle) * 9, y: sin(angle) * 9)
            spike.zRotation = angle
            container.addChild(spike)
        }

        // Outer freeze ring
        let ring = SKShapeNode(circleOfRadius: 15)
        ring.fillColor = SKColor.clear
        ring.strokeColor = SKColor(red: 0.6, green: 0.88, blue: 1.0, alpha: 0.3)
        ring.lineWidth = 1.5
        container.addChild(ring)

        // Slow rotation
        let rotate = SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 4.0))
        crystal.run(rotate)

        return container
    }

    func buildNode() -> SKNode {
        FrostTower.makeNode(at: position)
    }

    func fire(at enemy: EnemyNode, scene: SKScene, currentTime: TimeInterval) {
        lastFiredTime = currentTime

        let projectile = SKShapeNode(circleOfRadius: 6)
        projectile.fillColor = SKColor.cyan
        projectile.strokeColor = SKColor.white
        projectile.lineWidth = 1
        projectile.position = position
        projectile.zPosition = 5
        scene.addChild(projectile)

        let damage = type.damage
        let slowFactor = type.slowFactor ?? 0.4

        let targetPos = enemy.node.position
        let move = SKAction.move(to: targetPos, duration: 0.20)

        let impact = SKAction.run {
            enemy.applyDamage(damage)
            enemy.applySlow(factor: slowFactor, duration: 2.0)

            let freezeEffect = SKShapeNode(circleOfRadius: 20)
            freezeEffect.fillColor = SKColor.cyan.withAlphaComponent(0.3)
            freezeEffect.strokeColor = SKColor.cyan
            freezeEffect.lineWidth = 2
            freezeEffect.position = targetPos
            freezeEffect.zPosition = 5
            scene.addChild(freezeEffect)

            let shrink = SKAction.scale(to: 0.1, duration: 0.4)
            let fade = SKAction.fadeOut(withDuration: 0.4)
            freezeEffect.run(SKAction.sequence([
                SKAction.group([shrink, fade]),
                SKAction.removeFromParent()
            ]))

            projectile.removeFromParent()
        }

        projectile.run(SKAction.sequence([move, impact]))
    }
}
