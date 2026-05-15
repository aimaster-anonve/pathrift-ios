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

        // Wide base platform — 25pt (0.70× 36)
        let basePlat = SKShapeNode(ellipseOf: CGSize(width: 25, height: 8))
        basePlat.fillColor = SKColor(red: 0.02, green: 0.10, blue: 0.01, alpha: 1.0)
        basePlat.strokeColor = SKColor(red: 0.40, green: 1.00, blue: 0.10, alpha: 0.45)
        basePlat.lineWidth = 1.0
        basePlat.position = CGPoint(x: 0, y: -8)
        container.addChild(basePlat)

        // Floor shadow
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 25, height: 7))
        shadow.fillColor = SKColor(red: 0, green: 0, blue: 0, alpha: 0.35)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -11)
        container.addChild(shadow)

        // Elongated octagon body — 11×18pt (0.70× 16×26)
        let cut: CGFloat = 3.5
        let w: CGFloat = 5.5
        let h: CGFloat = 9
        let octPath = CGMutablePath()
        octPath.move(to: CGPoint(x: -w + cut, y: h))
        octPath.addLine(to: CGPoint(x: w - cut, y: h))
        octPath.addLine(to: CGPoint(x: w, y: h - cut))
        octPath.addLine(to: CGPoint(x: w, y: -h + cut))
        octPath.addLine(to: CGPoint(x: w - cut, y: -h))
        octPath.addLine(to: CGPoint(x: -w + cut, y: -h))
        octPath.addLine(to: CGPoint(x: -w, y: -h + cut))
        octPath.addLine(to: CGPoint(x: -w, y: h - cut))
        octPath.closeSubpath()
        let body = SKShapeNode(path: octPath)
        body.fillColor = SKColor(red: 0.04, green: 0.14, blue: 0.02, alpha: 1.0)
        body.strokeColor = SKColor(red: 0.40, green: 1.00, blue: 0.10, alpha: 1.0)
        body.lineWidth = 1.0
        container.addChild(body)

        // Reticle lines
        for yOff: CGFloat in [-1.5, 1.5] {
            let reticle = SKShapeNode(rectOf: CGSize(width: 8, height: 0.5))
            reticle.fillColor = SKColor(red: 0.40, green: 1.00, blue: 0.10, alpha: 0.50)
            reticle.strokeColor = .clear
            reticle.position = CGPoint(x: 0, y: yOff)
            reticle.name = "reticle"
            container.addChild(reticle)
        }

        // Barrel — 3×10pt (0.70× 4×14)
        let barrel = SKShapeNode(rectOf: CGSize(width: 3, height: 10), cornerRadius: 1)
        barrel.fillColor = SKColor(red: 0.40, green: 1.00, blue: 0.10, alpha: 1.0)
        barrel.strokeColor = .clear
        barrel.position = CGPoint(x: 0, y: 13)
        container.addChild(barrel)

        // Glow ring
        let glow = SKShapeNode(circleOfRadius: 10)
        glow.fillColor = SKColor.clear
        glow.strokeColor = SKColor(red: 0.6, green: 1.0, blue: 0.2, alpha: 0.0)
        glow.lineWidth = 0
        container.addChild(glow)
        glow.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.1, duration: 0.7),
            SKAction.fadeAlpha(to: 0.45, duration: 0.7)
        ])))

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
