import Foundation
import CoreGraphics
import SpriteKit

final class CoreTower: Tower {
    let type: TowerType = .core
    var position: CGPoint
    var slotId: Int
    var lastFiredTime: TimeInterval = 0
    let node: SKNode
    var level: Int = 1
    var totalInvested: Int

    init(position: CGPoint, slotId: Int) {
        self.position = position
        self.slotId = slotId
        self.totalInvested = 180
        self.node = CoreTower.makeNode(at: position)
    }

    static func makeNode(at position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position

        // Base
        let base = SKShapeNode(rectOf: CGSize(width: 36, height: 8), cornerRadius: 3)
        base.fillColor = SKColor(red: 0.20, green: 0.08, blue: 0.04, alpha: 1)
        base.strokeColor = SKColor(red: 1.0, green: 0.27, blue: 0.0, alpha: 0.6)
        base.lineWidth = 1.5
        base.position = CGPoint(x: 0, y: -12)
        container.addChild(base)

        // Heavy hex body
        let body = SKShapeNode(rectOf: CGSize(width: 28, height: 28), cornerRadius: 6)
        body.fillColor = SKColor(red: 0.18, green: 0.07, blue: 0.02, alpha: 1)
        body.strokeColor = SKColor(red: 1.0, green: 0.27, blue: 0.0, alpha: 1)
        body.lineWidth = 2.5
        container.addChild(body)

        // Core ember
        let ember = SKShapeNode(circleOfRadius: 7)
        ember.fillColor = SKColor(red: 1.0, green: 0.27, blue: 0.0, alpha: 1)
        ember.strokeColor = SKColor.clear
        container.addChild(ember)

        // Ring
        let ring = SKShapeNode(circleOfRadius: 16)
        ring.fillColor = SKColor.clear
        ring.strokeColor = SKColor(red: 1.0, green: 0.27, blue: 0.0, alpha: 0.3)
        ring.lineWidth = 2
        container.addChild(ring)

        // Armor-piercing drill tip
        let drill = SKShapeNode(rectOf: CGSize(width: 6, height: 16), cornerRadius: 3)
        drill.fillColor = SKColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 1)
        drill.strokeColor = SKColor.clear
        drill.position = CGPoint(x: 0, y: 18)
        container.addChild(drill)

        // Spin animation on ember
        let spin = SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 2.0))
        ember.run(spin)

        let pulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.15, duration: 0.6),
            SKAction.fadeAlpha(to: 0.5, duration: 0.6)
        ]))
        ring.run(pulse)

        return container
    }

    func buildNode() -> SKNode {
        CoreTower.makeNode(at: position)
    }

    func fire(at enemy: EnemyNode, scene: SKScene, currentTime: TimeInterval) {
        lastFiredTime = currentTime

        let projectile = SKShapeNode(circleOfRadius: 7)
        projectile.fillColor = type.projectileColor
        projectile.strokeColor = SKColor(red: 1.0, green: 0.6, blue: 0.3, alpha: 1)
        projectile.lineWidth = 1.5
        projectile.position = position
        projectile.zPosition = 5
        scene.addChild(projectile)

        let finalDamage = scaledDamage() * type.damageMultiplier(against: enemy.type)
        let targetPosition = enemy.node.position

        let move = SKAction.move(to: targetPosition, duration: 0.18)
        let impact = SKAction.run {
            enemy.applyDamageWithPenetration(finalDamage, penetration: 0.5)
            projectile.removeFromParent()

            // Impact flash
            let flash = SKShapeNode(circleOfRadius: 18)
            flash.fillColor = SKColor(red: 1.0, green: 0.27, blue: 0.0, alpha: 0.4)
            flash.strokeColor = SKColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 0.8)
            flash.lineWidth = 2
            flash.position = targetPosition
            flash.zPosition = 5
            scene.addChild(flash)
            flash.run(SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 1.6, duration: 0.15),
                    SKAction.fadeOut(withDuration: 0.15)
                ]),
                SKAction.removeFromParent()
            ]))
        }

        projectile.run(SKAction.sequence([move, impact]))

        // Drill spin on node
        let spin = SKAction.rotate(byAngle: .pi, duration: 0.3)
        node.run(spin)
    }
}
