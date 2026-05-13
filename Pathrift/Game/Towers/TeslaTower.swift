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

        // Base
        let base = SKShapeNode(rectOf: CGSize(width: 36, height: 8), cornerRadius: 3)
        base.fillColor = SKColor(red: 0.06, green: 0.14, blue: 0.22, alpha: 1)
        base.strokeColor = SKColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 0.6)
        base.lineWidth = 1.5
        base.position = CGPoint(x: 0, y: -12)
        container.addChild(base)

        // Body
        let body = SKShapeNode(circleOfRadius: 14)
        body.fillColor = SKColor(red: 0.06, green: 0.14, blue: 0.24, alpha: 1)
        body.strokeColor = SKColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 1)
        body.lineWidth = 2
        container.addChild(body)

        // Tesla coil center
        let coil = SKShapeNode(circleOfRadius: 5)
        coil.fillColor = SKColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 1)
        coil.strokeColor = SKColor.white
        coil.lineWidth = 1
        container.addChild(coil)

        // Tesla prongs
        for angle: CGFloat in [-.pi/4, .pi/4] {
            let prong = SKShapeNode(rectOf: CGSize(width: 3, height: 18), cornerRadius: 1)
            prong.fillColor = SKColor(red: 0.5, green: 0.9, blue: 1.0, alpha: 1)
            prong.strokeColor = SKColor.clear
            prong.position = CGPoint(x: sin(angle) * 6, y: 14)
            prong.zRotation = angle
            container.addChild(prong)
        }

        // Outer glow
        let glow = SKShapeNode(circleOfRadius: 17)
        glow.fillColor = SKColor.clear
        glow.strokeColor = SKColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 0.25)
        glow.lineWidth = 2
        container.addChild(glow)

        // Electric pulse
        let pulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.1, duration: 0.3),
            SKAction.fadeAlpha(to: 0.6, duration: 0.15),
            SKAction.fadeAlpha(to: 0.2, duration: 0.25),
            SKAction.fadeAlpha(to: 0.5, duration: 0.15)
        ]))
        glow.run(pulse)

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
