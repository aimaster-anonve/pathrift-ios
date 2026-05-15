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
        let cyanWhite = SKColor(red: 0.85, green: 1.00, blue: 1.00, alpha: 1.0)

        // Geniş hexagonal platform base (tabanlık)
        let basePath = CGMutablePath()
        let baseR: CGFloat = 14
        for i in 0..<6 {
            let angle = CGFloat(i) * (.pi / 3) + (.pi / 6)
            let pt = CGPoint(x: cos(angle) * baseR, y: sin(angle) * baseR - 10)
            i == 0 ? basePath.move(to: pt) : basePath.addLine(to: pt)
        }
        basePath.closeSubpath()
        let base = SKShapeNode(path: basePath)
        base.fillColor = SKColor(red: 0.08, green: 0.12, blue: 0.16, alpha: 1.0)
        base.strokeColor = cyanWhite.withAlphaComponent(0.5)
        base.lineWidth = 1.5
        container.addChild(base)

        // Turret body (geniş octagon, rotation platform)
        let turretPath = CGMutablePath()
        let tr: CGFloat = 10
        for i in 0..<8 {
            let angle = CGFloat(i) * (.pi / 4) + (.pi / 8)
            let pt = CGPoint(x: cos(angle) * tr, y: sin(angle) * tr)
            i == 0 ? turretPath.move(to: pt) : turretPath.addLine(to: pt)
        }
        turretPath.closeSubpath()
        let turret = SKShapeNode(path: turretPath)
        turret.fillColor = SKColor(red: 0.06, green: 0.10, blue: 0.14, alpha: 1.0)
        turret.strokeColor = cyanWhite
        turret.lineWidth = 1.5
        container.addChild(turret)

        // Scope housing (small rect on turret)
        let scopeHousing = SKShapeNode(rectOf: CGSize(width: 8, height: 6), cornerRadius: 2)
        scopeHousing.fillColor = SKColor(red: 0.10, green: 0.18, blue: 0.22, alpha: 1.0)
        scopeHousing.strokeColor = cyanWhite.withAlphaComponent(0.6)
        scopeHousing.lineWidth = 1.0
        scopeHousing.position = CGPoint(x: 0, y: 4)
        container.addChild(scopeHousing)

        // Lens circle
        let lens = SKShapeNode(circleOfRadius: 3)
        lens.fillColor = SKColor(red: 0.50, green: 0.85, blue: 1.00, alpha: 0.30)
        lens.strokeColor = cyanWhite
        lens.lineWidth = 0.8
        lens.position = CGPoint(x: 0, y: 4)
        container.addChild(lens)
        lens.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.15, duration: 1.2),
            SKAction.fadeAlpha(to: 0.50, duration: 1.2)
        ])))

        // Long barrel — still long (sniper feel) but mounted on proper turret
        let barrel = SKShapeNode(rectOf: CGSize(width: 4, height: 22), cornerRadius: 1.5)
        barrel.fillColor = cyanWhite
        barrel.strokeColor = .clear
        barrel.position = CGPoint(x: 0, y: 18)  // starts from turret top
        container.addChild(barrel)

        // Pulse on turret
        turret.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.run { turret.strokeColor = cyanWhite.withAlphaComponent(0.70) },
            SKAction.wait(forDuration: 1.8),
            SKAction.run { turret.strokeColor = cyanWhite },
            SKAction.wait(forDuration: 1.8)
        ])))

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
