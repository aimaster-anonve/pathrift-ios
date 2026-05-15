import Foundation
import CoreGraphics
import SpriteKit

final class TeslaTower: Tower {
    let type: TowerType = .tesla
    var position: CGPoint
    var slotId: Int
    var lastFiredTime: TimeInterval = 0
    let node: SKNode
    var level: Int = 1
    var totalInvested: Int

    init(position: CGPoint, slotId: Int) {
        self.position = position
        self.slotId = slotId
        self.totalInvested = 300
        self.node = TeslaTower.makeNode(at: position)
    }

    static func makeNode(at position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position

        // Wide base platform (tabanlık — 42pt wide, coil mounting plate)
        let basePlat = SKShapeNode(ellipseOf: CGSize(width: 42, height: 12))
        basePlat.fillColor = SKColor(red: 0.01, green: 0.06, blue: 0.12, alpha: 1.0)
        basePlat.strokeColor = SKColor(red: 0.20, green: 0.65, blue: 1.00, alpha: 0.50)
        basePlat.lineWidth = 1.5
        basePlat.position = CGPoint(x: 0, y: -14)
        container.addChild(basePlat)

        // Floor shadow
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 42, height: 10))
        shadow.fillColor = SKColor(red: 0, green: 0, blue: 0, alpha: 0.35)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -18)
        container.addChild(shadow)

        // Circle body radius 13
        let body = SKShapeNode(circleOfRadius: 13)
        body.fillColor = SKColor(red: 0.02, green: 0.08, blue: 0.18, alpha: 1.0)
        body.strokeColor = SKColor(red: 0.20, green: 0.65, blue: 1.00, alpha: 1.0)
        body.lineWidth = 1.5
        container.addChild(body)

        // Outer arc ring (capacitor coil: top semicircle 30°–150°)
        let arcPath1 = CGMutablePath()
        arcPath1.addArc(center: .zero, radius: 19, startAngle: .pi * 30 / 180, endAngle: .pi * 150 / 180, clockwise: false)
        let arc1 = SKShapeNode(path: arcPath1)
        arc1.strokeColor = SKColor(red: 0.20, green: 0.65, blue: 1.00, alpha: 0.70)
        arc1.lineWidth = 2.0
        arc1.fillColor = .clear
        arc1.name = "arc1"
        container.addChild(arc1)

        // Inner arc ring (60°–120°)
        let arcPath2 = CGMutablePath()
        arcPath2.addArc(center: .zero, radius: 16, startAngle: .pi * 60 / 180, endAngle: .pi * 120 / 180, clockwise: false)
        let arc2 = SKShapeNode(path: arcPath2)
        arc2.strokeColor = SKColor(red: 0.20, green: 0.65, blue: 1.00, alpha: 0.40)
        arc2.lineWidth = 1.0
        arc2.fillColor = .clear
        arc2.name = "arc2"
        container.addChild(arc2)

        // Arc oscillation ±8°
        arc1.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.rotate(byAngle: .pi * 8 / 180, duration: 0.7),
            SKAction.rotate(byAngle: -.pi * 8 / 180, duration: 0.7)
        ])))
        arc2.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.rotate(byAngle: -.pi * 8 / 180, duration: 0.7),
            SKAction.rotate(byAngle: .pi * 8 / 180, duration: 0.7)
        ])))

        // Barrel
        let barrel = SKShapeNode(rectOf: CGSize(width: 5, height: 10), cornerRadius: 1)
        barrel.fillColor = SKColor(red: 0.20, green: 0.65, blue: 1.00, alpha: 1.0)
        barrel.strokeColor = .clear
        barrel.position = CGPoint(x: 0, y: 16)
        container.addChild(barrel)

        return container
    }

    func buildNode() -> SKNode {
        TeslaTower.makeNode(at: position)
    }

    func fire(at enemy: EnemyNode, scene: SKScene, currentTime: TimeInterval) {
        lastFiredTime = currentTime

        let primaryDamage = scaledDamage() * type.damageMultiplier(against: enemy.type)
        enemy.applyDamage(primaryDamage)

        // Lightning bolt to primary
        drawLightningBolt(from: position, to: enemy.node.position, in: scene, color: type.projectileColor)

        // Chain lightning — find up to 2 other enemies within 150px
        guard let gameScene = scene as? GameScene else { return }
        let chainDamageBase: CGFloat = 18.0 * (1.0 + 0.25 * CGFloat(level - 1))
        let chainRadius: CGFloat = 150

        let chainTargets = gameScene.activeEnemies.filter { target in
            guard target.isAlive && target !== enemy else { return false }
            let dx = target.node.position.x - enemy.node.position.x
            let dy = target.node.position.y - enemy.node.position.y
            return sqrt(dx * dx + dy * dy) <= chainRadius
        }.prefix(2)

        for chainTarget in chainTargets {
            let chainDamage = chainDamageBase * type.damageMultiplier(against: chainTarget.type)
            chainTarget.applyDamage(chainDamage)
            drawLightningBolt(from: enemy.node.position, to: chainTarget.node.position, in: scene,
                              color: SKColor(red: 0.6, green: 0.9, blue: 1.0, alpha: 0.7))
        }

        // Tower animation
        let flash = SKAction.sequence([
            SKAction.scale(to: 1.25, duration: 0.06),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        node.run(flash)
    }

    private func drawLightningBolt(from start: CGPoint, to end: CGPoint, in scene: SKScene, color: SKColor) {
        // Zigzag lightning using multiple short segments
        let path = CGMutablePath()
        path.move(to: start)

        let segments = 5
        let dx = (end.x - start.x) / CGFloat(segments)
        let dy = (end.y - start.y) / CGFloat(segments)

        for i in 1..<segments {
            let baseX = start.x + dx * CGFloat(i)
            let baseY = start.y + dy * CGFloat(i)
            let offset = CGFloat.random(in: -8...8)
            let perpX = -dy / sqrt(dx*dx + dy*dy) * offset
            let perpY = dx / sqrt(dx*dx + dy*dy) * offset
            path.addLine(to: CGPoint(x: baseX + perpX, y: baseY + perpY))
        }
        path.addLine(to: end)

        let bolt = SKShapeNode(path: path)
        bolt.strokeColor = color
        bolt.lineWidth = 2
        bolt.zPosition = 6
        bolt.lineCap = .round
        scene.addChild(bolt)

        bolt.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.15),
            SKAction.removeFromParent()
        ]))
    }
}
