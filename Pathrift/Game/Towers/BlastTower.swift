import Foundation
import CoreGraphics
import SpriteKit

final class BlastTower: Tower {
    let type: TowerType = .blast
    var position: CGPoint
    var slotId: Int
    var lastFiredTime: TimeInterval = 0
    let node: SKNode
    var level: Int = 1
    var totalInvested: Int

    /// Called by GameScene to apply AoE damage to nearby enemies when shell impacts.
    var blastDamageCallback: ((CGPoint, CGFloat, CGFloat) -> Void)?

    init(position: CGPoint, slotId: Int) {
        self.position = position
        self.slotId = slotId
        self.totalInvested = EconomyConstants.TowerCost.blast
        self.node = BlastTower.makeNode(at: position)
    }

    static func makeNode(at position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position

        // Base
        let base = SKShapeNode(rectOf: CGSize(width: 36, height: 8), cornerRadius: 3)
        base.fillColor = SKColor(red: 0.20, green: 0.10, blue: 0.05, alpha: 1)
        base.strokeColor = SKColor(red: 1.0, green: 0.42, blue: 0.0, alpha: 0.7)
        base.lineWidth = 1.5
        base.position = CGPoint(x: 0, y: -12)
        container.addChild(base)

        // Heavy square body
        let body = SKShapeNode(rectOf: CGSize(width: 28, height: 28), cornerRadius: 5)
        body.fillColor = SKColor(red: 0.22, green: 0.10, blue: 0.04, alpha: 1)
        body.strokeColor = SKColor(red: 1.0, green: 0.42, blue: 0.0, alpha: 1)
        body.lineWidth = 2
        container.addChild(body)

        // Orange core ember
        let ember = SKShapeNode(circleOfRadius: 6)
        ember.fillColor = SKColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 1)
        ember.strokeColor = SKColor.clear
        container.addChild(ember)

        // Vents left/right
        for xOff: CGFloat in [-10, 10] {
            let vent = SKShapeNode(rectOf: CGSize(width: 5, height: 12), cornerRadius: 2)
            vent.fillColor = SKColor(red: 0.8, green: 0.3, blue: 0.0, alpha: 0.9)
            vent.strokeColor = SKColor.clear
            vent.position = CGPoint(x: xOff, y: 2)
            container.addChild(vent)
        }

        // Mortar tube at top
        let tube = SKShapeNode(rectOf: CGSize(width: 8, height: 14), cornerRadius: 3)
        tube.fillColor = SKColor(red: 0.5, green: 0.25, blue: 0.0, alpha: 1)
        tube.strokeColor = SKColor(red: 1.0, green: 0.42, blue: 0.0, alpha: 0.6)
        tube.lineWidth = 1
        tube.position = CGPoint(x: 0, y: 18)
        container.addChild(tube)

        // Flicker effect on ember
        let flicker = SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.15),
            SKAction.scale(to: 0.85, duration: 0.15),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
        ember.run(flicker)

        return container
    }

    func buildNode() -> SKNode {
        BlastTower.makeNode(at: position)
    }

    func fire(at enemy: EnemyNode, scene: SKScene, currentTime: TimeInterval) {
        lastFiredTime = currentTime

        let shell = SKShapeNode(circleOfRadius: 8)
        shell.fillColor = type.projectileColor
        shell.strokeColor = SKColor.white
        shell.lineWidth = 1
        shell.position = position
        shell.zPosition = 5
        scene.addChild(shell)

        let targetPos = enemy.node.position
        let blastRadius = type.blastRadius ?? 96
        let damage = scaledDamage() * type.damageMultiplier(against: enemy.type)

        let move = SKAction.move(to: targetPos, duration: 0.25)
        let blastCallback = blastDamageCallback
        let explode = SKAction.run { [weak scene] in
            shell.removeFromParent()
            guard let scene = scene else { return }

            let explosion = SKShapeNode(circleOfRadius: blastRadius)
            explosion.fillColor = SKColor.orange.withAlphaComponent(0.4)
            explosion.strokeColor = SKColor.orange
            explosion.lineWidth = 2
            explosion.position = targetPos
            explosion.zPosition = 5
            scene.addChild(explosion)

            let expand = SKAction.scale(to: 1.5, duration: 0.2)
            let fade = SKAction.fadeOut(withDuration: 0.2)
            explosion.run(SKAction.sequence([
                SKAction.group([expand, fade]),
                SKAction.removeFromParent()
            ]))

            blastCallback?(targetPos, blastRadius, damage)
        }

        shell.run(SKAction.sequence([move, explode]))

        let shakeX = SKAction.sequence([
            SKAction.moveBy(x: 3, y: 0, duration: 0.05),
            SKAction.moveBy(x: -6, y: 0, duration: 0.05),
            SKAction.moveBy(x: 3, y: 0, duration: 0.05)
        ])
        node.run(shakeX)
    }
}
