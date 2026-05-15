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

        // Floor shadow
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 28, height: 10))
        shadow.fillColor = SKColor(red: 0, green: 0, blue: 0, alpha: 0.35)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -14)
        container.addChild(shadow)

        // Narrow tall rectangle body (10pt wide × 32pt tall, clipped corners 2pt)
        let bodyPath = CGMutablePath()
        let w: CGFloat = 5, h: CGFloat = 16, clip: CGFloat = 2
        bodyPath.move(to: CGPoint(x: -w + clip, y: h))
        bodyPath.addLine(to: CGPoint(x: w - clip, y: h))
        bodyPath.addLine(to: CGPoint(x: w, y: h - clip))
        bodyPath.addLine(to: CGPoint(x: w, y: -h + clip))
        bodyPath.addLine(to: CGPoint(x: w - clip, y: -h))
        bodyPath.addLine(to: CGPoint(x: -w + clip, y: -h))
        bodyPath.addLine(to: CGPoint(x: -w, y: -h + clip))
        bodyPath.addLine(to: CGPoint(x: -w, y: h - clip))
        bodyPath.closeSubpath()
        let body = SKShapeNode(path: bodyPath)
        body.fillColor = SKColor(red: 0.06, green: 0.10, blue: 0.12, alpha: 1.0)
        body.strokeColor = cyanWhite
        body.lineWidth = 1.25
        container.addChild(body)

        // Scope circle (centered on body at 30% from top — at y = h*0.4)
        let scopeY: CGFloat = h * 0.4
        let scope = SKShapeNode(circleOfRadius: 3.5)
        scope.fillColor = SKColor(red: 0.60, green: 0.90, blue: 1.00, alpha: 0.25)
        scope.strokeColor = cyanWhite
        scope.lineWidth = 1.0
        scope.position = CGPoint(x: 0, y: scopeY)
        scope.name = "scope"
        container.addChild(scope)

        // Scope crosshair
        let crossH = SKShapeNode(rectOf: CGSize(width: 7, height: 0.5))
        crossH.fillColor = cyanWhite
        crossH.strokeColor = .clear
        crossH.position = CGPoint(x: 0, y: scopeY)
        container.addChild(crossH)

        // Slow scope rotation
        scope.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 12.0)))

        // Stroke alpha breathe
        body.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.run { body.strokeColor = cyanWhite.withAlphaComponent(0.70) },
            SKAction.wait(forDuration: 1.5),
            SKAction.run { body.strokeColor = cyanWhite.withAlphaComponent(1.00) },
            SKAction.wait(forDuration: 1.5)
        ])))

        // Long barrel (longest of all towers)
        let barrel = SKShapeNode(rectOf: CGSize(width: 3, height: 16), cornerRadius: 1)
        barrel.fillColor = cyanWhite
        barrel.strokeColor = .clear
        barrel.position = CGPoint(x: 0, y: h + 8)
        container.addChild(barrel)

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
