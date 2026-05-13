import Foundation
import CoreGraphics
import SpriteKit

final class BlastTower: Tower {
    let type: TowerType = .blast
    var position: CGPoint
    let slotId: Int
    var lastFiredTime: TimeInterval = 0
    let node: SKNode

    /// Called by GameScene to apply AoE damage to nearby enemies when shell impacts.
    var blastDamageCallback: ((CGPoint, CGFloat, CGFloat) -> Void)?

    init(position: CGPoint, slotId: Int) {
        self.position = position
        self.slotId = slotId
        self.node = BlastTower.makeNode(at: position)
    }

    static func makeNode(at position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position

        let base = SKShapeNode(rectOf: CGSize(width: 34, height: 34), cornerRadius: 4)
        base.fillColor = TowerType.blast.nodeColor
        base.strokeColor = SKColor.white
        base.lineWidth = 2
        container.addChild(base)

        let top = SKShapeNode(circleOfRadius: 10)
        top.fillColor = SKColor(red: 1.0, green: 0.6, blue: 0.1, alpha: 1)
        top.position = CGPoint(x: 0, y: 6)
        container.addChild(top)

        let ventL = SKShapeNode(rectOf: CGSize(width: 4, height: 14))
        ventL.fillColor = SKColor(red: 0.8, green: 0.3, blue: 0.0, alpha: 1)
        ventL.position = CGPoint(x: -10, y: 0)
        container.addChild(ventL)

        let ventR = SKShapeNode(rectOf: CGSize(width: 4, height: 14))
        ventR.fillColor = SKColor(red: 0.8, green: 0.3, blue: 0.0, alpha: 1)
        ventR.position = CGPoint(x: 10, y: 0)
        container.addChild(ventR)

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
        let damage = type.damage

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
