import Foundation
import CoreGraphics
import SpriteKit

final class PierceTower: Tower {
    let type: TowerType = .pierce
    var position: CGPoint
    var slotId: Int
    var lastFiredTime: TimeInterval = 0
    let node: SKNode
    var level: Int = 1
    var totalInvested: Int

    init(position: CGPoint, slotId: Int) {
        self.position = position
        self.slotId = slotId
        self.totalInvested = 130
        self.node = PierceTower.makeNode(at: position)
    }

    static func makeNode(at position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position

        // Base
        let base = SKShapeNode(rectOf: CGSize(width: 36, height: 8), cornerRadius: 3)
        base.fillColor = SKColor(red: 0.08, green: 0.18, blue: 0.06, alpha: 1)
        base.strokeColor = SKColor(red: 0.6, green: 1.0, blue: 0.2, alpha: 0.6)
        base.lineWidth = 1.5
        base.position = CGPoint(x: 0, y: -12)
        container.addChild(base)

        // Body
        let body = SKShapeNode(rectOf: CGSize(width: 24, height: 24), cornerRadius: 4)
        body.fillColor = SKColor(red: 0.08, green: 0.18, blue: 0.04, alpha: 1)
        body.strokeColor = SKColor(red: 0.6, green: 1.0, blue: 0.2, alpha: 1)
        body.lineWidth = 2
        container.addChild(body)

        // Core
        let core = SKShapeNode(circleOfRadius: 5)
        core.fillColor = SKColor(red: 0.6, green: 1.0, blue: 0.2, alpha: 1)
        core.strokeColor = SKColor.clear
        container.addChild(core)

        // Arrow barrel (long thin spike)
        let barrel = SKShapeNode(rectOf: CGSize(width: 3, height: 20), cornerRadius: 1)
        barrel.fillColor = SKColor(red: 0.7, green: 1.0, blue: 0.4, alpha: 1)
        barrel.strokeColor = SKColor.clear
        barrel.position = CGPoint(x: 0, y: 16)
        container.addChild(barrel)

        // Tip arrowhead
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 6))
        path.addLine(to: CGPoint(x: -4, y: 0))
        path.addLine(to: CGPoint(x: 4, y: 0))
        path.closeSubpath()
        let tip = SKShapeNode(path: path)
        tip.fillColor = SKColor(red: 0.6, green: 1.0, blue: 0.2, alpha: 1)
        tip.strokeColor = SKColor.clear
        tip.position = CGPoint(x: 0, y: 26)
        container.addChild(tip)

        // Glow ring
        let glow = SKShapeNode(circleOfRadius: 14)
        glow.fillColor = SKColor.clear
        glow.strokeColor = SKColor(red: 0.6, green: 1.0, blue: 0.2, alpha: 0.25)
        glow.lineWidth = 2
        container.addChild(glow)

        let pulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.1, duration: 0.7),
            SKAction.fadeAlpha(to: 0.45, duration: 0.7)
        ]))
        glow.run(pulse)

        return container
    }

    func buildNode() -> SKNode {
        PierceTower.makeNode(at: position)
    }

    func fire(at enemy: EnemyNode, scene: SKScene, currentTime: TimeInterval) {
        lastFiredTime = currentTime
        // Pierce hits all alive enemies in range that are on the line from this tower through the target
        guard let gameScene = scene as? GameScene else { return }
        let allInRange = gameScene.activeEnemies.filter { $0.isAlive && isInRange($0) }
            .sorted { $0.pathProgress < $1.pathProgress }

        for target in allInRange {
            let finalDamage = scaledDamage() * type.damageMultiplier(against: target.type)
            if target.type == .shield {
                target.applyDamagePiercing(finalDamage)
            } else {
                target.applyDamage(finalDamage)
            }

            // Visual: draw a fast thin line effect to each target
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: position)
            path.addLine(to: target.node.position)
            line.path = path
            line.strokeColor = type.projectileColor
            line.lineWidth = 2
            line.zPosition = 5
            scene.addChild(line)
            line.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.12),
                SKAction.removeFromParent()
            ]))
        }
    }
}
