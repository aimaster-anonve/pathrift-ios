import Foundation
import CoreGraphics
import SpriteKit

final class FrostTower: Tower {
    let type: TowerType = .frost
    var position: CGPoint
    let slotId: Int
    var lastFiredTime: TimeInterval = 0
    let node: SKNode

    init(position: CGPoint, slotId: Int) {
        self.position = position
        self.slotId = slotId
        self.node = FrostTower.makeNode(at: position)
    }

    static func makeNode(at position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position

        let base = SKShapeNode(circleOfRadius: 18)
        base.fillColor = TowerType.frost.nodeColor
        base.strokeColor = SKColor.white
        base.lineWidth = 2
        container.addChild(base)

        let crystal = FrostTower.makeCrystalShape()
        crystal.fillColor = SKColor.cyan.withAlphaComponent(0.8)
        crystal.strokeColor = SKColor.white
        crystal.lineWidth = 1
        container.addChild(crystal)

        let rotateForever = SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 3.0))
        crystal.run(rotateForever)

        let glow = SKShapeNode(circleOfRadius: 22)
        glow.strokeColor = SKColor.cyan
        glow.lineWidth = 1
        glow.alpha = 0.4
        let glowFade = SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.8, duration: 1.0),
            SKAction.fadeAlpha(to: 0.2, duration: 1.0)
        ]))
        glow.run(glowFade)
        container.addChild(glow)

        return container
    }

    private static func makeCrystalShape() -> SKShapeNode {
        let path = CGMutablePath()
        let points: [(CGFloat, CGFloat)] = [
            (0, 16), (6, 6), (16, 0),
            (6, -6), (0, -16), (-6, -6),
            (-16, 0), (-6, 6)
        ]
        path.move(to: CGPoint(x: points[0].0, y: points[0].1))
        for p in points.dropFirst() {
            path.addLine(to: CGPoint(x: p.0, y: p.1))
        }
        path.closeSubpath()
        return SKShapeNode(path: path)
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

        let damage = type.damage
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
