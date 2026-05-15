import Foundation
import CoreGraphics
import SpriteKit

final class NovaTower: Tower {
    let type: TowerType = .nova
    var position: CGPoint
    var slotId: Int
    var lastFiredTime: TimeInterval = 0
    let node: SKNode
    var level: Int = 1
    var totalInvested: Int

    /// Called by GameScene to apply AoE damage to all enemies within nova radius.
    var novaDamageCallback: ((CGPoint, CGFloat, CGFloat) -> Void)?

    init(position: CGPoint, slotId: Int) {
        self.position = position
        self.slotId = slotId
        self.totalInvested = 500
        self.node = NovaTower.makeNode(at: position)
    }

    static func makeNode(at position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position

        // Wide base platform — 29pt (0.70× 42)
        let basePlat = SKShapeNode(ellipseOf: CGSize(width: 29, height: 8))
        basePlat.fillColor = SKColor(red: 0.12, green: 0.10, blue: 0.00, alpha: 1.0)
        basePlat.strokeColor = SKColor(red: 1.00, green: 0.82, blue: 0.10, alpha: 0.50)
        basePlat.lineWidth = 1.0
        basePlat.position = CGPoint(x: 0, y: -10)
        container.addChild(basePlat)

        // Floor shadow
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 29, height: 7))
        shadow.fillColor = SKColor(red: 0, green: 0, blue: 0, alpha: 0.35)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -13)
        container.addChild(shadow)

        // 6-pointed star body — outer radius 10 (0.70× 14), inner radius 5 (0.70× 7)
        let starPath = CGMutablePath()
        for i in 0..<12 {
            let angle = CGFloat(i) * (.pi / 6) - (.pi / 2)
            let r: CGFloat = i.isMultiple(of: 2) ? 10 : 5
            let pt = CGPoint(x: cos(angle) * r, y: sin(angle) * r)
            i == 0 ? starPath.move(to: pt) : starPath.addLine(to: pt)
        }
        starPath.closeSubpath()
        let body = SKShapeNode(path: starPath)
        body.fillColor = SKColor(red: 0.18, green: 0.14, blue: 0.00, alpha: 1.0)
        body.strokeColor = SKColor(red: 1.00, green: 0.82, blue: 0.10, alpha: 1.0)
        body.lineWidth = 1.0
        container.addChild(body)

        // Center core lens — radius 3 (0.70× 4)
        let coreLens = SKShapeNode(circleOfRadius: 3)
        coreLens.fillColor = SKColor(red: 1.00, green: 0.82, blue: 0.10, alpha: 0.60)
        coreLens.strokeColor = SKColor(red: 1.00, green: 0.82, blue: 0.10, alpha: 1.0)
        coreLens.lineWidth = 0.75
        container.addChild(coreLens)

        body.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 8.0)))
        coreLens.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.5),
            SKAction.scale(to: 0.9, duration: 0.5)
        ])))

        // Barrel — 3×7pt (0.70× 5×10)
        let barrel = SKShapeNode(rectOf: CGSize(width: 3, height: 7), cornerRadius: 1)
        barrel.fillColor = SKColor(red: 1.00, green: 0.82, blue: 0.10, alpha: 1.0)
        barrel.strokeColor = .clear
        barrel.position = CGPoint(x: 0, y: 11)
        container.addChild(barrel)

        return container
    }

    func buildNode() -> SKNode {
        NovaTower.makeNode(at: position)
    }

    func fire(at enemy: EnemyNode, scene: SKScene, currentTime: TimeInterval) {
        lastFiredTime = currentTime

        let novaRadius = type.blastRadius ?? 160
        let damage = scaledDamage() * type.damageMultiplier(against: enemy.type)
        let targetPos = enemy.node.position

        // Charging projectile
        let orb = SKShapeNode(circleOfRadius: 12)
        orb.fillColor = type.projectileColor.withAlphaComponent(0.7)
        orb.strokeColor = SKColor.white
        orb.lineWidth = 2
        orb.position = position
        orb.zPosition = 5
        scene.addChild(orb)

        let novaCallback = novaDamageCallback
        let move = SKAction.move(to: targetPos, duration: 0.35)
        let burst = SKAction.run { [weak scene] in
            orb.removeFromParent()
            guard let scene = scene else { return }

            // Nova burst visual
            let burstRing = SKShapeNode(circleOfRadius: novaRadius)
            burstRing.fillColor = SKColor(red: 1.0, green: 0.95, blue: 0.5, alpha: 0.2)
            burstRing.strokeColor = SKColor(red: 1.0, green: 0.95, blue: 0.5, alpha: 0.9)
            burstRing.lineWidth = 3
            burstRing.position = targetPos
            burstRing.zPosition = 5
            scene.addChild(burstRing)

            // Inner bright flash
            let innerFlash = SKShapeNode(circleOfRadius: 30)
            innerFlash.fillColor = SKColor.white.withAlphaComponent(0.8)
            innerFlash.strokeColor = SKColor.clear
            innerFlash.position = targetPos
            innerFlash.zPosition = 6
            scene.addChild(innerFlash)

            burstRing.run(SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 1.3, duration: 0.3),
                    SKAction.fadeOut(withDuration: 0.3)
                ]),
                SKAction.removeFromParent()
            ]))
            innerFlash.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.removeFromParent()
            ]))

            novaCallback?(targetPos, novaRadius, damage)
        }

        orb.run(SKAction.sequence([move, burst]))

        // Charging glow on tower
        let charge = SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.15)
        ])
        node.run(charge)
    }
}
