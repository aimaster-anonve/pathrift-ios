import Foundation
import CoreGraphics
import SpriteKit

final class BoltTower: Tower {
    let type: TowerType = .bolt
    var position: CGPoint
    let slotId: Int
    var lastFiredTime: TimeInterval = 0
    let node: SKNode

    init(position: CGPoint, slotId: Int) {
        self.position = position
        self.slotId = slotId
        self.node = BoltTower.makeNode(at: position)
    }

    static func makeNode(at position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position

        let base = SKShapeNode(circleOfRadius: 18)
        base.fillColor = TowerType.bolt.nodeColor
        base.strokeColor = SKColor.white
        base.lineWidth = 2
        container.addChild(base)

        let barrel = SKShapeNode(rectOf: CGSize(width: 6, height: 22), cornerRadius: 2)
        barrel.fillColor = SKColor.white
        barrel.position = CGPoint(x: 0, y: 14)
        container.addChild(barrel)

        let glowEffect = SKShapeNode(circleOfRadius: 20)
        glowEffect.strokeColor = TowerType.bolt.nodeColor
        glowEffect.lineWidth = 1
        glowEffect.alpha = 0.5
        container.addChild(glowEffect)

        let pulseIn = SKAction.scale(to: 1.05, duration: 0.8)
        let pulseOut = SKAction.scale(to: 0.95, duration: 0.8)
        let pulse = SKAction.repeatForever(SKAction.sequence([pulseIn, pulseOut]))
        container.run(pulse)

        return container
    }

    func buildNode() -> SKNode {
        BoltTower.makeNode(at: position)
    }

    func fire(at enemy: EnemyNode, scene: SKScene, currentTime: TimeInterval) {
        lastFiredTime = currentTime

        let projectile = SKShapeNode(circleOfRadius: 5)
        projectile.fillColor = type.projectileColor
        projectile.strokeColor = SKColor.white
        projectile.lineWidth = 1
        projectile.position = position
        projectile.zPosition = 5

        scene.addChild(projectile)

        let damage = type.damage
        let targetPosition = enemy.node.position

        let move = SKAction.move(to: targetPosition, duration: 0.15)
        let flash = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.05),
            SKAction.fadeAlpha(to: 1.0, duration: 0.05)
        ])
        let impact = SKAction.run {
            enemy.applyDamage(damage)
            projectile.removeFromParent()
        }

        projectile.run(SKAction.sequence([
            SKAction.group([move, SKAction.repeat(flash, count: 3)]),
            impact
        ]))

        let rotateBarrel = SKAction.rotate(byAngle: .pi * 2, duration: 0.2)
        node.run(rotateBarrel)
    }
}
