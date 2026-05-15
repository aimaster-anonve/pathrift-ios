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

        // Shadow — 11×4pt (0.70× 16×6)
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 11, height: 4))
        shadow.fillColor = SKColor(red: 0, green: 0, blue: 0, alpha: 0.30)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -8)
        container.addChild(shadow)

        // Elongated oval capsule — 7×11pt (0.70× 10×16)
        let capsulePath = CGMutablePath()
        capsulePath.addEllipse(in: CGRect(x: -3.5, y: -5.5, width: 7, height: 11))
        let body = SKShapeNode(path: capsulePath)
        body.fillColor = SKColor(red: 0.00, green: 0.25, blue: 0.70, alpha: 1.0)
        body.strokeColor = SKColor(red: 0.20, green: 0.60, blue: 1.00, alpha: 1.0)
        body.lineWidth = 1.0
        container.addChild(body)

        // 3 motion lines — 0.70× widths
        let lineWidths: [CGFloat] = [4, 7, 8]
        for (i, lw) in lineWidths.enumerated() {
            let line = SKShapeNode(rectOf: CGSize(width: lw, height: 0.5))
            line.fillColor = SKColor(red: 0.30, green: 0.70, blue: 1.00, alpha: 0.60)
            line.strokeColor = .clear
            line.position = CGPoint(x: 0, y: CGFloat(-7 - i * 2))
            container.addChild(line)
        }

        // Health bar
        let (bg, bar) = RunnerEnemy.makeHealthBarNodes()
        container.addChild(bg)
        container.addChild(bar)

        body.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scaleX(to: 0.92, y: 1.0, duration: 0.15),
            SKAction.scaleX(to: 1.0, y: 1.0, duration: 0.15)
        ])))

        return container
    }
}
