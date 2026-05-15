import Foundation
import CoreGraphics
import SpriteKit

final class InfernoTower: Tower {
    let type: TowerType = .inferno
    var position: CGPoint
    var slotId: Int
    var lastFiredTime: TimeInterval = 0
    let node: SKNode
    var level: Int = 1
    var totalInvested: Int

    init(position: CGPoint, slotId: Int) {
        self.position = position
        self.slotId = slotId
        self.totalInvested = 200
        self.node = InfernoTower.makeNode(at: position)
    }

    static func makeNode(at position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position

        // Wide base platform (tabanlık — 40pt wide)
        let basePlat = SKShapeNode(ellipseOf: CGSize(width: 40, height: 12))
        basePlat.fillColor = SKColor(red: 0.14, green: 0.02, blue: 0.00, alpha: 1.0)
        basePlat.strokeColor = SKColor(red: 1.00, green: 0.18, blue: 0.08, alpha: 0.50)
        basePlat.lineWidth = 1.5
        basePlat.position = CGPoint(x: 0, y: -14)
        container.addChild(basePlat)

        // Floor shadow
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 40, height: 10))
        shadow.fillColor = SKColor(red: 0, green: 0, blue: 0, alpha: 0.35)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -18)
        container.addChild(shadow)

        // Irregular pentagon body (asymmetric, left-lean flame silhouette)
        let pentPath = CGMutablePath()
        pentPath.move(to: CGPoint(x: 0, y: 14))
        pentPath.addLine(to: CGPoint(x: 12, y: 4))
        pentPath.addLine(to: CGPoint(x: 10, y: -14))
        pentPath.addLine(to: CGPoint(x: -11, y: -14))
        pentPath.addLine(to: CGPoint(x: -13, y: 5))
        pentPath.closeSubpath()
        let body = SKShapeNode(path: pentPath)
        body.fillColor = SKColor(red: 0.20, green: 0.03, blue: 0.00, alpha: 1.0)
        body.strokeColor = SKColor(red: 1.00, green: 0.18, blue: 0.08, alpha: 1.0)
        body.lineWidth = 1.75
        container.addChild(body)

        // 3 upward flame tip triangles on top edge
        let flameTips: [(CGFloat, CGFloat, CGFloat)] = [(-6, 14, 6), (0, 18, 5), (6, 14, 6)]
        for (i, (fx, fy, fh)) in flameTips.enumerated() {
            let flamePath = CGMutablePath()
            flamePath.move(to: CGPoint(x: fx, y: fy + fh))
            flamePath.addLine(to: CGPoint(x: fx - 2, y: fy))
            flamePath.addLine(to: CGPoint(x: fx + 2, y: fy))
            flamePath.closeSubpath()
            let flame = SKShapeNode(path: flamePath)
            flame.fillColor = SKColor(red: 1.00, green: 0.55, blue: 0.10, alpha: 0.80)
            flame.strokeColor = .clear
            container.addChild(flame)
            // Flicker animation per flame
            let dur = Double.random(in: 0.2...0.5)
            let offset = Double(i) * 0.15
            flame.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.wait(forDuration: offset),
                SKAction.group([
                    SKAction.scale(to: 1.15, duration: dur),
                    SKAction.fadeAlpha(to: 0.6, duration: dur)
                ]),
                SKAction.group([
                    SKAction.scale(to: 0.9, duration: dur),
                    SKAction.fadeAlpha(to: 1.0, duration: dur)
                ])
            ])))
        }

        // Barrel (pointing up)
        let barrel = SKShapeNode(rectOf: CGSize(width: 5, height: 11), cornerRadius: 1)
        barrel.fillColor = SKColor(red: 1.00, green: 0.18, blue: 0.08, alpha: 1.0)
        barrel.strokeColor = .clear
        barrel.position = CGPoint(x: 0, y: 16)
        container.addChild(barrel)

        return container
    }

    func buildNode() -> SKNode {
        InfernoTower.makeNode(at: position)
    }

    func fire(at enemy: EnemyNode, scene: SKScene, currentTime: TimeInterval) {
        lastFiredTime = currentTime

        // Inferno bypasses ghost slow immunity (handled at type level via damageMultiplier)
        // For ghost: also apply a small slow via direct speed override (ignore ghost immunity)
        if enemy.type == .ghost {
            // Force slow even though ghost is normally immune
            enemy.currentSpeed = enemy.baseSpeed * 0.65
            enemy.slowTimer = CACurrentMediaTime() + 1.5
        }

        let orb = SKShapeNode(circleOfRadius: 5)
        orb.fillColor = type.projectileColor
        orb.strokeColor = SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 0.8)
        orb.lineWidth = 1.5
        orb.position = position
        orb.zPosition = 5
        scene.addChild(orb)

        // Trailing fire effect
        let trail = SKShapeNode(circleOfRadius: 3)
        trail.fillColor = SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 0.5)
        trail.strokeColor = SKColor.clear
        trail.position = position
        trail.zPosition = 4
        scene.addChild(trail)

        let finalDamage = scaledDamage() * type.damageMultiplier(against: enemy.type)
        let targetPos = enemy.node.position

        let move = SKAction.move(to: targetPos, duration: 0.12)
        let trailMove = SKAction.move(to: targetPos, duration: 0.18)

        let impact = SKAction.run {
            enemy.applyDamage(finalDamage)
            orb.removeFromParent()

            let fireEffect = SKShapeNode(circleOfRadius: 14)
            fireEffect.fillColor = SKColor(red: 1.0, green: 0.3, blue: 0.0, alpha: 0.35)
            fireEffect.strokeColor = SKColor(red: 1.0, green: 0.15, blue: 0.0, alpha: 0.7)
            fireEffect.lineWidth = 1.5
            fireEffect.position = targetPos
            fireEffect.zPosition = 5
            scene.addChild(fireEffect)
            fireEffect.run(SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 1.5, duration: 0.15),
                    SKAction.fadeOut(withDuration: 0.15)
                ]),
                SKAction.removeFromParent()
            ]))
        }

        orb.run(SKAction.sequence([move, impact]))
        trail.run(SKAction.sequence([
            trailMove,
            SKAction.fadeOut(withDuration: 0.1),
            SKAction.removeFromParent()
        ]))
    }
}
