import Foundation
import CoreGraphics
import SpriteKit

final class SniperTower: Tower {
    let type: TowerType = .sniper
    var position: CGPoint
    var slotId: Int
    var lastFiredTime: TimeInterval = 0
    let node: SKNode
    var level: Int = 1
    var totalInvested: Int

    init(position: CGPoint, slotId: Int) {
        self.position = position
        self.slotId = slotId
        self.totalInvested = TowerType.sniper.cost
        self.node = SniperTower.makeNode(at: position)
    }

    static func makeNode(at position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position

        let cyanWhite = SKColor(red: 0.4, green: 1.0, blue: 1.0, alpha: 1)

        // Base platform
        let base = SKShapeNode(rectOf: CGSize(width: 32, height: 6), cornerRadius: 2)
        base.fillColor = SKColor(red: 0.05, green: 0.15, blue: 0.20, alpha: 1)
        base.strokeColor = cyanWhite.withAlphaComponent(0.5)
        base.lineWidth = 1
        base.position = CGPoint(x: 0, y: -13)
        container.addChild(base)

        // Hexagonal-ish body (circle with outer glow ring)
        let body = SKShapeNode(circleOfRadius: 14)
        body.fillColor = SKColor(red: 0.05, green: 0.20, blue: 0.22, alpha: 1)
        body.strokeColor = cyanWhite
        body.lineWidth = 2.0
        container.addChild(body)

        // Inner core
        let core = SKShapeNode(circleOfRadius: 5)
        core.fillColor = cyanWhite
        core.strokeColor = SKColor.clear
        container.addChild(core)

        // Tall barrel (pointing up)
        let barrel = SKShapeNode(rectOf: CGSize(width: 3, height: 20), cornerRadius: 1)
        barrel.fillColor = SKColor(red: 0.3, green: 0.8, blue: 0.85, alpha: 1)
        barrel.strokeColor = SKColor.clear
        barrel.position = CGPoint(x: 0, y: 18)
        container.addChild(barrel)

        // Barrel tip
        let tip = SKShapeNode(circleOfRadius: 2.5)
        tip.fillColor = cyanWhite
        tip.strokeColor = SKColor.clear
        tip.position = CGPoint(x: 0, y: 28)
        container.addChild(tip)

        // Outer glow ring
        let ring = SKShapeNode(circleOfRadius: 17)
        ring.fillColor = SKColor.clear
        ring.strokeColor = cyanWhite.withAlphaComponent(0.25)
        ring.lineWidth = 1.5
        container.addChild(ring)

        // Pulse animation on core
        let pulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.6),
            SKAction.scale(to: 0.8, duration: 0.6)
        ]))
        core.run(pulse)

        return container
    }

    func buildNode() -> SKNode {
        SniperTower.makeNode(at: position)
    }

    func fire(at enemy: EnemyNode, scene: SKScene, currentTime: TimeInterval) {
        lastFiredTime = currentTime

        let targetPos = enemy.node.position
        let damage = scaledDamage() * type.damageMultiplier(against: enemy.type)

        // Long thin sniper beam
        let path = CGMutablePath()
        path.move(to: position)
        path.addLine(to: targetPos)

        let beam = SKShapeNode(path: path)
        beam.strokeColor = type.projectileColor
        beam.lineWidth = 2.0
        beam.zPosition = 5
        beam.alpha = 1.0
        scene.addChild(beam)

        // Muzzle flash at tower
        let flash = SKShapeNode(circleOfRadius: 5)
        flash.fillColor = type.projectileColor
        flash.strokeColor = SKColor.clear
        flash.position = position
        flash.zPosition = 6
        scene.addChild(flash)

        // Impact marker at target
        let impact = SKShapeNode(circleOfRadius: 6)
        impact.fillColor = type.projectileColor.withAlphaComponent(0.5)
        impact.strokeColor = type.projectileColor
        impact.lineWidth = 1.5
        impact.position = targetPos
        impact.zPosition = 6
        scene.addChild(impact)

        // Animate: beam fades quickly, instant hit
        beam.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.12),
            SKAction.removeFromParent()
        ]))
        flash.run(SKAction.sequence([
            SKAction.scale(to: 1.8, duration: 0.06),
            SKAction.fadeOut(withDuration: 0.08),
            SKAction.removeFromParent()
        ]))
        impact.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.6, duration: 0.12),
                SKAction.fadeOut(withDuration: 0.12)
            ]),
            SKAction.removeFromParent()
        ]))

        // Instant damage
        enemy.applyDamage(damage)

        // Recoil animation on tower
        node.run(SKAction.sequence([
            SKAction.moveBy(x: 0, y: -3, duration: 0.04),
            SKAction.moveBy(x: 0, y: 3, duration: 0.08)
        ]))
    }
}
