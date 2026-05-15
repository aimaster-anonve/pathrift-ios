import Foundation
import CoreGraphics
import SpriteKit

final class RunnerEnemy: EnemyNode {
    let type: EnemyType = .runner
    let maxHP: CGFloat
    var currentHP: CGFloat
    let baseSpeed: CGFloat = 72   // ~half speed — gives towers time to fire
    var currentSpeed: CGFloat
    let armor: CGFloat = 0.0
    let goldReward: Int = EconomyConstants.EnemyGoldReward.runner
    var pathProgress: CGFloat = 0
    var hasReachedEnd: Bool = false
    var slowTimer: TimeInterval = 0
    var pathLayer: PathLayer = .ground
    let node: SKNode

    init(hpMultiplier: CGFloat = 1.0) {
        let hp = 50 * hpMultiplier
        self.maxHP = hp
        self.currentHP = hp
        self.currentSpeed = baseSpeed
        self.node = RunnerEnemy.makeNode()
        self.node.position = PathSystem.waypoints.first ?? .zero
    }

    private static func makeNode() -> SKNode {
        let container = SKNode()
        container.zPosition = 4

        // Shadow
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 16, height: 6))
        shadow.fillColor = SKColor(red: 0, green: 0, blue: 0, alpha: 0.30)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -12)
        container.addChild(shadow)

        // Elongated oval capsule (teardrop, front-pointed)
        let capsulePath = CGMutablePath()
        capsulePath.addEllipse(in: CGRect(x: -5, y: -8, width: 10, height: 16))
        let body = SKShapeNode(path: capsulePath)
        body.fillColor = SKColor(red: 0.00, green: 0.25, blue: 0.70, alpha: 1.0)
        body.strokeColor = SKColor(red: 0.20, green: 0.60, blue: 1.00, alpha: 1.0)
        body.lineWidth = 1.25
        container.addChild(body)

        // 3 horizontal motion lines trailing behind (pointing backward from travel direction)
        let lineWidths: [CGFloat] = [6, 10, 12]
        for (i, lw) in lineWidths.enumerated() {
            let line = SKShapeNode(rectOf: CGSize(width: lw, height: 0.75))
            line.fillColor = SKColor(red: 0.30, green: 0.70, blue: 1.00, alpha: 0.60)
            line.strokeColor = .clear
            line.position = CGPoint(x: 0, y: CGFloat(-10 - i * 3))
            container.addChild(line)
        }

        // Health bar
        let (bg, bar) = RunnerEnemy.makeHealthBarNodes()
        container.addChild(bg)
        container.addChild(bar)

        // Running pulse animation (body compression/extension on X)
        body.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scaleX(to: 0.92, y: 1.0, duration: 0.15),
            SKAction.scaleX(to: 1.0, y: 1.0, duration: 0.15)
        ])))

        return container
    }
}
