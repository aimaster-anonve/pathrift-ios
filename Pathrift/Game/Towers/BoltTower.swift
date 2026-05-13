import Foundation
import CoreGraphics
import SpriteKit

final class BoltTower: Tower {
    let type: TowerType = .bolt
    var position: CGPoint
    var slotId: Int
    var lastFiredTime: TimeInterval = 0
    let node: SKNode
    var level: Int = 1
    var totalInvested: Int

    init(position: CGPoint, slotId: Int) {
        self.position = position
        self.slotId = slotId
        self.totalInvested = EconomyConstants.TowerCost.bolt
        self.node = BoltTower.makeNode(at: position)
    }

    static func makeNode(at position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position

        // Base platform
        let base = SKShapeNode(rectOf: CGSize(width: 36, height: 8), cornerRadius: 3)
        base.fillColor = SKColor(red: 0.15, green: 0.15, blue: 0.25, alpha: 1)
        base.strokeColor = SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: 0.6)
        base.lineWidth = 1.5
        base.position = CGPoint(x: 0, y: -12)
        container.addChild(base)

        // Tower body (hexagon-ish using circle)
        let body = SKShapeNode(circleOfRadius: 14)
        body.fillColor = SKColor(red: 0.06, green: 0.18, blue: 0.35, alpha: 1)
        body.strokeColor = SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: 1)
        body.lineWidth = 2
        container.addChild(body)

        // Glowing core
        let core = SKShapeNode(circleOfRadius: 5)
        core.fillColor = SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: 1)
        core.strokeColor = SKColor.clear
        container.addChild(core)

        // Outer glow ring
        let glow = SKShapeNode(circleOfRadius: 16)
        glow.fillColor = SKColor.clear
        glow.strokeColor = SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: 0.3)
        glow.lineWidth = 2
        container.addChild(glow)

        // Barrel
        let barrel = SKShapeNode(rectOf: CGSize(width: 4, height: 16), cornerRadius: 2)
        barrel.fillColor = SKColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 1)
        barrel.strokeColor = SKColor.clear
        barrel.position = CGPoint(x: 0, y: 14)
        container.addChild(barrel)

        // Pulse animation on glow
        let pulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.15, duration: 0.8),
            SKAction.fadeAlpha(to: 0.5, duration: 0.8)
        ]))
        glow.run(pulse)

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

        let finalDamage = scaledDamage() * type.damageMultiplier(against: enemy.type)
        let targetPosition = enemy.node.position

        let move = SKAction.move(to: targetPosition, duration: 0.15)
        let flash = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.05),
            SKAction.fadeAlpha(to: 1.0, duration: 0.05)
        ])
        let impact = SKAction.run {
            enemy.applyDamage(finalDamage)
            projectile.removeFromParent()
        }

        projectile.run(SKAction.sequence([
            SKAction.group([move, SKAction.repeat(flash, count: 3)]),
            impact
        ]))
    }
}
