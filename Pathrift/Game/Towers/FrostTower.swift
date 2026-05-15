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

        // Wide base platform — 28pt (0.70× 40)
        let basePlat = SKShapeNode(ellipseOf: CGSize(width: 28, height: 8))
        basePlat.fillColor = SKColor(red: 0.04, green: 0.01, blue: 0.10, alpha: 1.0)
        basePlat.strokeColor = SKColor(red: 0.56, green: 0.18, blue: 1.00, alpha: 0.45)
        basePlat.lineWidth = 1.0
        basePlat.position = CGPoint(x: 0, y: -8)
        container.addChild(basePlat)

        // Floor shadow
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 28, height: 7))
        shadow.fillColor = SKColor(red: 0, green: 0, blue: 0, alpha: 0.35)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -12)
        container.addChild(shadow)

        // Diamond body — 10pt half-radius (0.70× 14)
        let diamPath = CGMutablePath()
        diamPath.move(to: CGPoint(x: 0, y: 10))
        diamPath.addLine(to: CGPoint(x: 10, y: 0))
        diamPath.addLine(to: CGPoint(x: 0, y: -10))
        diamPath.addLine(to: CGPoint(x: -10, y: 0))
        diamPath.closeSubpath()
        let body = SKShapeNode(path: diamPath)
        body.fillColor = SKColor(red: 0.06, green: 0.02, blue: 0.14, alpha: 1.0)
        body.strokeColor = SKColor(red: 0.56, green: 0.18, blue: 1.00, alpha: 1.0)
        body.lineWidth = 1.0
        container.addChild(body)

        // 4 ice crystal spikes at diamond corners
        let tipCorners: [(CGFloat, CGFloat)] = [(0, 10), (10, 0), (0, -10), (-10, 0)]
        let tipAngles: [CGFloat] = [.pi/2, 0, -.pi/2, .pi]
        for (i, (cx, cy)) in tipCorners.enumerated() {
            let tipPath = CGMutablePath()
            tipPath.move(to: CGPoint(x: 0, y: 6))
            tipPath.addLine(to: CGPoint(x: -2, y: 0))
            tipPath.addLine(to: CGPoint(x: 2, y: 0))
            tipPath.closeSubpath()
            let tip = SKShapeNode(path: tipPath)
            tip.fillColor = SKColor(red: 0.70, green: 0.85, blue: 1.00, alpha: 0.70)
            tip.strokeColor = .clear
            tip.position = CGPoint(x: cx, y: cy)
            tip.zRotation = tipAngles[i]
            container.addChild(tip)
            let delay = Double(i) * 0.45
            tip.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.scale(to: 1.2, duration: 0.45),
                SKAction.scale(to: 1.0, duration: 0.45)
            ])))
        }

        // Barrel — 3×7pt (0.70× 4×10)
        let barrel = SKShapeNode(rectOf: CGSize(width: 3, height: 7), cornerRadius: 1)
        barrel.fillColor = SKColor(red: 0.56, green: 0.18, blue: 1.00, alpha: 1.0)
        barrel.strokeColor = .clear
        barrel.position = CGPoint(x: 0, y: 11)
        container.addChild(barrel)

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

        let damage = scaledDamage() * type.damageMultiplier(against: enemy.type)
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
