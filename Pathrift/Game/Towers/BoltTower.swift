import Foundation
import CoreGraphics
import SpriteKit

final class BoltTower: Tower {
    let type: TowerType = .bolt
    var position: CGPoint
    var slotId: Int
    var lastFiredTime: TimeInterval = 0
    let node: SKNode
    var level: Int = 1
    var totalInvested: Int

    init(position: CGPoint, slotId: Int) {
        self.position = position
        self.slotId = slotId
        self.totalInvested = EconomyConstants.TowerCost.bolt
        self.node = BoltTower.makeNode(at: position)
    }

    static func makeNode(at position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position

        // Wide base platform — 28pt wide (0.70× 40)
        let basePlat = SKShapeNode(ellipseOf: CGSize(width: 28, height: 8))
        basePlat.fillColor = SKColor(red: 0.04, green: 0.08, blue: 0.14, alpha: 1.0)
        basePlat.strokeColor = SKColor(red: 0.00, green: 0.78, blue: 1.00, alpha: 0.45)
        basePlat.lineWidth = 1.0
        basePlat.position = CGPoint(x: 0, y: -8)
        container.addChild(basePlat)

        // Floor shadow
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 28, height: 7))
        shadow.fillColor = SKColor(red: 0, green: 0, blue: 0, alpha: 0.35)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -12)
        container.addChild(shadow)

        // Hexagon body (flat-top, radius 11 — 0.70× 16)
        let hexPath = CGMutablePath()
        for i in 0..<6 {
            let a = CGFloat(i) * (.pi / 3)
            let pt = CGPoint(x: cos(a) * 11, y: sin(a) * 11)
            i == 0 ? hexPath.move(to: pt) : hexPath.addLine(to: pt)
        }
        hexPath.closeSubpath()
        let body = SKShapeNode(path: hexPath)
        body.fillColor = SKColor(red: 0.00, green: 0.12, blue: 0.22, alpha: 1.0)
        body.strokeColor = SKColor(red: 0.00, green: 0.78, blue: 1.00, alpha: 1.0)
        body.lineWidth = 1.5
        container.addChild(body)

        // Circuit trace lines on hex faces (3 diagonals)
        let traceAngles: [CGFloat] = [.pi/6, .pi/2, 5 * .pi/6]
        for angle in traceAngles {
            let trace = SKShapeNode()
            let tracePath = CGMutablePath()
            tracePath.move(to: CGPoint(x: cos(angle) * -7, y: sin(angle) * -7))
            tracePath.addLine(to: CGPoint(x: cos(angle) * 7, y: sin(angle) * 7))
            trace.path = tracePath
            trace.strokeColor = SKColor(red: 0.0, green: 0.78, blue: 1.0, alpha: 0.6)
            trace.lineWidth = 0.5
            trace.lineCap = .round
            container.addChild(trace)
            let delay = Double.random(in: 0...0.5)
            let duration = Double.random(in: 0.3...0.7)
            trace.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.fadeAlpha(to: 0.4, duration: duration),
                SKAction.fadeAlpha(to: 0.9, duration: duration)
            ])))
        }

        // Glow ring
        let glowRing = SKShapeNode(circleOfRadius: 13)
        glowRing.fillColor = .clear
        glowRing.strokeColor = SKColor(red: 0.00, green: 0.78, blue: 1.00, alpha: 0.30)
        glowRing.lineWidth = 1.5
        container.addChild(glowRing)
        glowRing.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.12, duration: 1.0),
            SKAction.fadeAlpha(to: 0.40, duration: 1.0)
        ])))

        // Barrel (pointing up, +Y) — 3×8pt (0.70× 5×11)
        let barrel = SKShapeNode(rectOf: CGSize(width: 3, height: 8), cornerRadius: 1.5)
        barrel.fillColor = SKColor(red: 0.00, green: 0.78, blue: 1.00, alpha: 1.0)
        barrel.strokeColor = .clear
        barrel.position = CGPoint(x: 0, y: 13)
        container.addChild(barrel)

        return container
    }

    func buildNode() -> SKNode {
        BoltTower.makeNode(at: position)
    }

    func fire(at enemy: EnemyNode, scene: SKScene, currentTime: TimeInterval) {
        lastFiredTime = currentTime

        let projectile = SKShapeNode(circleOfRadius: 5)
        projectile.fillColor = type.projectileColor
        projectile.strokeColor = SKColor.white
        projectile.lineWidth = 1
        projectile.position = position
        projectile.zPosition = 5

        scene.addChild(projectile)

        let finalDamage = scaledDamage() * type.damageMultiplier(against: enemy.type)
        let targetPosition = enemy.node.position

        let move = SKAction.move(to: targetPosition, duration: 0.15)
        let flash = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.05),
            SKAction.fadeAlpha(to: 1.0, duration: 0.05)
        ])
        let impact = SKAction.run {
            enemy.applyDamage(finalDamage)
            projectile.removeFromParent()
        }

        projectile.run(SKAction.sequence([
            SKAction.group([move, SKAction.repeat(flash, count: 3)]),
            impact
        ]))
    }
}
