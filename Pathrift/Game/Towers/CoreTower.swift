import Foundation
import CoreGraphics
import SpriteKit

final class CoreTower: Tower {
    let type: TowerType = .core
    var position: CGPoint
    var slotId: Int
    var lastFiredTime: TimeInterval = 0
    let node: SKNode
    var level: Int = 1
    var totalInvested: Int

    init(position: CGPoint, slotId: Int) {
        self.position = position
        self.slotId = slotId
        self.totalInvested = 180
        self.node = CoreTower.makeNode(at: position)
    }

    static func makeNode(at position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position

        // Wide base platform — 28pt (0.70× 40)
        let basePlat = SKShapeNode(ellipseOf: CGSize(width: 28, height: 8))
        basePlat.fillColor = SKColor(red: 0.12, green: 0.03, blue: 0.00, alpha: 1.0)
        basePlat.strokeColor = SKColor(red: 1.00, green: 0.35, blue: 0.05, alpha: 0.50)
        basePlat.lineWidth = 1.0
        basePlat.position = CGPoint(x: 0, y: -10)
        container.addChild(basePlat)

        // Floor shadow
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 28, height: 7))
        shadow.fillColor = SKColor(red: 0, green: 0, blue: 0, alpha: 0.35)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -13)
        container.addChild(shadow)

        // Square body 18×18 (0.70× 26)
        let body = SKShapeNode(rectOf: CGSize(width: 18, height: 18))
        body.fillColor = SKColor(red: 0.18, green: 0.05, blue: 0.00, alpha: 1.0)
        body.strokeColor = SKColor(red: 1.00, green: 0.35, blue: 0.05, alpha: 1.0)
        body.lineWidth = 1.5
        container.addChild(body)

        // Thin diagonal cross
        for angle in [CGFloat.pi / 4, -CGFloat.pi / 4] {
            let cross = SKShapeNode()
            let crossPath = CGMutablePath()
            crossPath.move(to: CGPoint(x: cos(angle) * -8, y: sin(angle) * -8))
            crossPath.addLine(to: CGPoint(x: cos(angle) * 8, y: sin(angle) * 8))
            cross.path = crossPath
            cross.strokeColor = SKColor(red: 1.00, green: 0.35, blue: 0.05, alpha: 0.30)
            cross.lineWidth = 0.5
            container.addChild(cross)
        }

        // 4 corner rivets — 1.5pt radius (0.70× 2.5)
        let rivetPositions: [CGPoint] = [
            CGPoint(x: -6, y: 6), CGPoint(x: 6, y: 6),
            CGPoint(x: -6, y: -6), CGPoint(x: 6, y: -6)
        ]
        for (i, rPos) in rivetPositions.enumerated() {
            let rivet = SKShapeNode(circleOfRadius: 1.5)
            rivet.fillColor = SKColor(red: 0.90, green: 0.28, blue: 0.04, alpha: 1.0)
            rivet.strokeColor = SKColor(red: 1.00, green: 0.35, blue: 0.05, alpha: 1.0)
            rivet.lineWidth = 0.5
            rivet.position = rPos
            container.addChild(rivet)
            let delay = Double(i) * 0.3
            rivet.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.fadeAlpha(to: 0.70, duration: 0.4),
                SKAction.fadeAlpha(to: 1.00, duration: 0.4)
            ])))
        }

        // Barrel — 5×7pt (0.70× 7×10)
        let barrel = SKShapeNode(rectOf: CGSize(width: 5, height: 7), cornerRadius: 1)
        barrel.fillColor = SKColor(red: 1.00, green: 0.35, blue: 0.05, alpha: 1.0)
        barrel.strokeColor = .clear
        barrel.position = CGPoint(x: 0, y: 11)
        container.addChild(barrel)

        return container
    }

    func buildNode() -> SKNode {
        CoreTower.makeNode(at: position)
    }

    func fire(at enemy: EnemyNode, scene: SKScene, currentTime: TimeInterval) {
        lastFiredTime = currentTime

        let projectile = SKShapeNode(circleOfRadius: 7)
        projectile.fillColor = type.projectileColor
        projectile.strokeColor = SKColor(red: 1.0, green: 0.6, blue: 0.3, alpha: 1)
        projectile.lineWidth = 1.5
        projectile.position = position
        projectile.zPosition = 5
        scene.addChild(projectile)

        let finalDamage = scaledDamage() * type.damageMultiplier(against: enemy.type)
        let targetPosition = enemy.node.position

        let move = SKAction.move(to: targetPosition, duration: 0.18)
        let impact = SKAction.run {
            enemy.applyDamageWithPenetration(finalDamage, penetration: 0.5)
            projectile.removeFromParent()

            // Impact flash
            let flash = SKShapeNode(circleOfRadius: 18)
            flash.fillColor = SKColor(red: 1.0, green: 0.27, blue: 0.0, alpha: 0.4)
            flash.strokeColor = SKColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 0.8)
            flash.lineWidth = 2
            flash.position = targetPosition
            flash.zPosition = 5
            scene.addChild(flash)
            flash.run(SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 1.6, duration: 0.15),
                    SKAction.fadeOut(withDuration: 0.15)
                ]),
                SKAction.removeFromParent()
            ]))
        }

        projectile.run(SKAction.sequence([move, impact]))
    }
}
