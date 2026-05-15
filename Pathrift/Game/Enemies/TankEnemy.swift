import Foundation
import CoreGraphics
import SpriteKit

final class TankEnemy: EnemyNode {
    let type: EnemyType = .tank
    let maxHP: CGFloat
    var currentHP: CGFloat
    let baseSpeed: CGFloat = 32   // deliberately slow — requires sustained DPS
    var currentSpeed: CGFloat
    let armor: CGFloat = 0.2
    let goldReward: Int = EconomyConstants.EnemyGoldReward.tank
    var pathProgress: CGFloat = 0
    var hasReachedEnd: Bool = false
    var slowTimer: TimeInterval = 0
    var pathLayer: PathLayer = .ground
    let node: SKNode

    init(hpMultiplier: CGFloat = 1.0) {
        let hp = 300 * hpMultiplier
        self.maxHP = hp
        self.currentHP = hp
        self.currentSpeed = 50
        self.node = TankEnemy.makeNode()
        self.node.position = PathSystem.waypoints.first ?? .zero
    }

    private static func makeNode() -> SKNode {
        let container = SKNode()
        container.zPosition = 4

        // Shadow
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 22, height: 8))
        shadow.fillColor = SKColor(red: 0, green: 0, blue: 0, alpha: 0.30)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -12)
        container.addChild(shadow)

        // Heavy chamfered square body (20×20, corner cut 3)
        let chamPath = CGMutablePath()
        let s: CGFloat = 10, c: CGFloat = 3
        chamPath.move(to: CGPoint(x: -s + c, y: s))
        chamPath.addLine(to: CGPoint(x: s - c, y: s))
        chamPath.addLine(to: CGPoint(x: s, y: s - c))
        chamPath.addLine(to: CGPoint(x: s, y: -s + c))
        chamPath.addLine(to: CGPoint(x: s - c, y: -s))
        chamPath.addLine(to: CGPoint(x: -s + c, y: -s))
        chamPath.addLine(to: CGPoint(x: -s, y: -s + c))
        chamPath.addLine(to: CGPoint(x: -s, y: s - c))
        chamPath.closeSubpath()
        let body = SKShapeNode(path: chamPath)
        body.fillColor = SKColor(red: 0.20, green: 0.18, blue: 0.14, alpha: 1.0)
        body.strokeColor = SKColor(red: 0.50, green: 0.45, blue: 0.35, alpha: 1.0)
        body.lineWidth = 2.0
        container.addChild(body)

        // 2 armor plate seam lines (horizontal)
        for yOff: CGFloat in [3, -3] {
            let seam = SKShapeNode(rectOf: CGSize(width: 16, height: 0.75))
            seam.fillColor = SKColor(red: 0.55, green: 0.50, blue: 0.40, alpha: 0.60)
            seam.strokeColor = .clear
            seam.position = CGPoint(x: 0, y: yOff)
            container.addChild(seam)
        }

        // 4 rivet dots at corners
        let rivetPos: [CGPoint] = [
            CGPoint(x: -7, y: 7), CGPoint(x: 7, y: 7),
            CGPoint(x: -7, y: -7), CGPoint(x: 7, y: -7)
        ]
        for rp in rivetPos {
            let rivet = SKShapeNode(circleOfRadius: 1.5)
            rivet.fillColor = SKColor(red: 0.50, green: 0.45, blue: 0.35, alpha: 1.0)
            rivet.strokeColor = .clear
            rivet.position = rp
            container.addChild(rivet)
        }

        // Health bar (positioned higher)
        let (bg, bar) = TankEnemy.makeHealthBarNodes()
        bg.position = CGPoint(x: 0, y: 24)
        bar.position = CGPoint(x: 0, y: 24)
        container.addChild(bg)
        container.addChild(bar)

        // Heavy footstep Y offset ±1
        container.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x: 0, y: 1, duration: 0.5),
            SKAction.moveBy(x: 0, y: -1, duration: 0.5)
        ])))

        return container
    }
}
