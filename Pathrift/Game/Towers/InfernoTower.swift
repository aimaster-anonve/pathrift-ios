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

        // Base
        let base = SKShapeNode(rectOf: CGSize(width: 36, height: 8), cornerRadius: 3)
        base.fillColor = SKColor(red: 0.22, green: 0.04, blue: 0.02, alpha: 1)
        base.strokeColor = SKColor(red: 1.0, green: 0.15, blue: 0.0, alpha: 0.7)
        base.lineWidth = 1.5
        base.position = CGPoint(x: 0, y: -12)
        container.addChild(base)

        // Body — angular fire shape
        let body = SKShapeNode(circleOfRadius: 13)
        body.fillColor = SKColor(red: 0.20, green: 0.04, blue: 0.02, alpha: 1)
        body.strokeColor = SKColor(red: 1.0, green: 0.15, blue: 0.0, alpha: 1)
        body.lineWidth = 2
        container.addChild(body)

        // Inferno core
        let core = SKShapeNode(circleOfRadius: 6)
        core.fillColor = SKColor(red: 1.0, green: 0.15, blue: 0.0, alpha: 1)
        core.strokeColor = SKColor.clear
        container.addChild(core)

        // Flame spikes
        let spikeParams: [(CGFloat, CGFloat)] = [
            (0, 14),
            (CGFloat.pi / 3, 10),
            (2 * CGFloat.pi / 3, 12),
            (CGFloat.pi, 14),
            (4 * CGFloat.pi / 3, 10),
            (5 * CGFloat.pi / 3, 12)
        ]
        for (angle, height) in spikeParams {
            let spike = SKShapeNode(rectOf: CGSize(width: 2.5, height: height), cornerRadius: 1)
            spike.fillColor = SKColor(red: 1.0, green: 0.35, blue: 0.0, alpha: 0.85)
            spike.strokeColor = SKColor.clear
            spike.position = CGPoint(x: cos(angle) * 10, y: sin(angle) * 10)
            spike.zRotation = angle
            container.addChild(spike)
        }

        // Flicker
        let flicker = SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 0.08),
            SKAction.scale(to: 0.9, duration: 0.08),
            SKAction.scale(to: 1.05, duration: 0.06),
            SKAction.scale(to: 1.0, duration: 0.08)
        ]))
        core.run(flicker)

        // Glow
        let glow = SKShapeNode(circleOfRadius: 16)
        glow.fillColor = SKColor.clear
        glow.strokeColor = SKColor(red: 1.0, green: 0.15, blue: 0.0, alpha: 0.3)
        glow.lineWidth = 2
        container.addChild(glow)

        let pulseGlow = SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.1, duration: 0.2),
            SKAction.fadeAlpha(to: 0.55, duration: 0.2)
        ]))
        glow.run(pulseGlow)

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
